# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    class HttpClient
      extend HttpHelper
      class << self
        def request(url, method, payload: nil, headers: {}, config: {})
          uri = URI(url)
          http = configure_http(uri, config)
          request = build_request(method, uri, payload, headers)
          http.request(request)
        end
      end
    end
  end
end
