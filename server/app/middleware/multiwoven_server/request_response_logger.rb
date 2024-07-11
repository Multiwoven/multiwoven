# frozen_string_literal: true

module MultiwovenServer
  class RequestResponseLogger
    def initialize(app)
      @app = app
    end

    def call(env)
      log_request(env)

      status, headers, response = @app.call(env)

      log_response(status, headers, response)

      [status, headers, response]
    end

    private

    def log_request(env)
      return unless ENV["APPSIGNAL_PUSH_API_KEY"]

      request = ActionDispatch::Request.new(env)
      Rails.logger.info({
        request_method: request.request_method,
        request_url: request.url,
        request_params: request.parameters,
        request_headers: { "Workspace-Id": request.headers["Workspace-Id"] }
      }.to_s)
    end

    def log_response(status, headers, response)
      return unless ENV["APPSIGNAL_PUSH_API_KEY"]

      Rails.logger.info({
        response_status: status,
        response_headers: headers.to_json,
        response_body: response.body
      }.to_s)
    end
  end
end
