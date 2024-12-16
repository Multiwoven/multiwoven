# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    class StreamingHttpClient
      extend HttpHelper
      class << self
        def request(url, method, payload: nil, headers: {}, config: {})
          uri = URI(url)
          http = configure_http(uri, config)
          request = build_request(method, uri, payload, headers)
          http.request(request) do |response|
            response.read_body do |chunk|
              yield chunk if block_given? # Pass each response chunk
            end
          end
        end
      end
    end
  end
end
