# frozen_string_literal: true

module Multiwoven
  module Integrations::Core
    class HttpClient
      extend HttpHelper
      class << self
        def request(url, method, payload: nil, headers: {}, options: {})
          config  = options[:config]  || {}
          params  = options[:params]  || {}
          uri = URI(url)

          if params && !params.empty?
            query = URI.encode_www_form(params)
            uri.query = [uri.query, query].compact.join("&")
          end

          http = configure_http(uri, config)
          request = build_request(method, uri, payload, headers)
          http.request(request)
        end
      end
    end
  end
end
