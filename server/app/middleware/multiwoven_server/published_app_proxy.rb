# frozen_string_literal: true

require "net/http"

module MultiwovenServer
  # Streams {label}.{APPGEN_PUBLISHED_DOMAIN} requests to the app's current deployment.
  class PublishedAppProxy # rubocop:disable Metrics/ClassLength
    UUID_PATTERN = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/
    HOP_BY_HOP_HEADERS = %w[connection keep-alive proxy-authenticate proxy-authorization
                            te trailer trailers transfer-encoding upgrade].freeze
    HTTP_METHODS = %w[GET HEAD POST PUT PATCH DELETE OPTIONS].freeze
    OPEN_TIMEOUT = 10
    READ_TIMEOUT = 300 # published apps may stream long LLM responses

    def initialize(app)
      @app = app
    end

    def call(env)
      deploy_url = resolve_published_app(env)
      return @app.call(env) unless deploy_url
      return text_response(501, "WebSocket connections are not supported") if websocket_upgrade?(env)

      proxy(env, URI.parse(deploy_url))
    rescue StandardError => e
      Rails.logger.error("[PublishedAppProxy] proxy failed host=#{env['HTTP_HOST']} " \
                         "error=#{e.class}: #{e.message}")
      text_response(502, "Upstream unavailable")
    end

    private

    def resolve_published_app(env)
      label = published_app_label(env)
      return nil unless label

      resolve_deploy_url(label)
    end

    def published_app_label(env)
      domain = ENV.fetch("APPGEN_PUBLISHED_DOMAIN", "")
      return nil if domain.empty?

      host = request_host(env)
      suffix = ".#{domain.downcase}"
      return nil unless host.end_with?(suffix)

      label = host.delete_suffix(suffix)
      return nil unless Utils::Slug.valid?(label)
      return nil if Utils::Slug.reserved?(label)

      label
    end

    def request_host(env)
      (env["HTTP_HOST"] || env["SERVER_NAME"]).to_s.split(":").first.to_s.downcase
    end

    def resolve_deploy_url(label)
      return nil unless defined?(::AgenticCoding::Deployment)

      Rails.application.executor.wrap do
        scope = ::AgenticCoding::Deployment
                .where(status: :succeeded)
                .where.not(deploy_url: [nil, ""])
        scope = if label.match?(UUID_PATTERN)
                  scope.where(agentic_coding_app_id: label)
                else
                  scope.joins(:agentic_coding_app).where(agentic_coding_apps: { slug: label })
                end
        coalesce = "COALESCE(agentic_coding_deployments.deployed_at, agentic_coding_deployments.created_at) DESC"
        scope.order(Arel.sql(coalesce)).limit(1).pick(:deploy_url)
      end
    end

    def proxy(env, target)
      request = build_request(env, target)
      stream_upstream(target, request, request_host(env))
    end

    def build_request(env, target)
      path = env["PATH_INFO"].to_s
      path = "/" if path.empty?
      query = env["QUERY_STRING"].to_s
      path = "#{path}?#{query}" unless query.empty?

      method = env["REQUEST_METHOD"]
      method = "GET" unless HTTP_METHODS.include?(method)
      request = Net::HTTP.const_get(method.capitalize).new(path)
      copy_request_headers(env, request, target.host)
      attach_request_body(env, request)
      request
    end

    def copy_request_headers(env, request, target_host)
      forward_client_headers(env, request)
      request["content-type"] = env["CONTENT_TYPE"] if env["CONTENT_TYPE"]
      request["host"] = target_host
      request["x-forwarded-host"] = request_host(env)
      request["x-forwarded-proto"] = "https"
      forwarded_for = [env["HTTP_X_FORWARDED_FOR"], env["REMOTE_ADDR"]].compact.reject(&:empty?)
      request["x-forwarded-for"] = forwarded_for.join(", ") if forwarded_for.any?
    end

    def forward_client_headers(env, request)
      env.each do |key, value|
        next unless key.is_a?(String) && key.start_with?("HTTP_")

        name = key.delete_prefix("HTTP_").tr("_", "-").downcase
        next if %w[host version].include?(name) || HOP_BY_HOP_HEADERS.include?(name)

        request[name] = value
      end
    end

    def attach_request_body(env, request)
      return unless request.request_body_permitted?

      input = env["rack.input"]
      return if input.nil?

      length = env["CONTENT_LENGTH"].to_i
      if length.positive?
        request.content_length = length
        request.body_stream = input
      else
        body = input.read
        request.body = body unless body.empty?
      end
    end

    # Body streams from a worker thread so status/headers return immediately (SSE/LLM streaming).
    def stream_upstream(target, request, public_host)
      chunks = SizedQueue.new(64)
      head = Queue.new
      worker = start_upstream_worker(target, request, head, chunks, public_host)

      result = head.pop
      raise "upstream worker exited without a response" if result.nil?
      raise result if result.is_a?(Exception)

      status, headers = result
      [status, headers, StreamingBody.new(chunks, worker)]
    end

    def start_upstream_worker(target, request, head, chunks, public_host)
      Thread.new do
        http = Net::HTTP.new(target.host, target.port)
        http.use_ssl = target.scheme == "https"
        http.open_timeout = OPEN_TIMEOUT
        http.read_timeout = READ_TIMEOUT
        http.start do |conn|
          conn.request(request) do |response|
            head << [response.code.to_i, response_headers(response, target.host, public_host)]
            response.read_body { |chunk| safe_push(chunks, chunk) }
          end
        end
      # rubocop:disable Lint/RescueException -- thread boundary: anything not
      # surfaced to the request thread would deadlock head.pop; re-raised there.
      rescue Exception => e
        # rubocop:enable Lint/RescueException
        head << e
        Rails.logger.warn("[PublishedAppProxy] upstream error: #{e.class}: #{e.message}")
      ensure
        safe_push(chunks, nil)
        head.close
      end
    end

    def safe_push(queue, item)
      queue.push(item)
    rescue ClosedQueueError
      nil
    end

    def response_headers(response, target_host, public_host)
      headers = {}
      response.each_name do |name|
        key = name.downcase
        next if HOP_BY_HOP_HEADERS.include?(key)

        values = response.get_fields(name)
        headers[key] = values.length == 1 ? values.first : values
      end
      rewrite_location!(headers, target_host, public_host)
      headers
    end

    # Rewrite absolute redirects to the public host so the tunnel host never leaks.
    def rewrite_location!(headers, target_host, public_host)
      location = headers["location"]
      return unless location.is_a?(String) && location.include?(target_host)

      headers["location"] = location.sub("://#{target_host}", "://#{public_host}")
    end

    def websocket_upgrade?(env)
      env["HTTP_UPGRADE"].to_s.casecmp("websocket").zero?
    end

    def text_response(status, message)
      [status, { "content-type" => "text/plain" }, [message]]
    end
  end
end

require_relative "published_app_proxy/streaming_body"
