require 'fastlane/action'
require_relative '../helper/jira_tempo_helper'

module Fastlane
  module Actions
    module SharedValues
      TEMPO_API_STATUS_CODE = :TEMPO_API_STATUS_CODE
      TEMPO_API_RESPONSE = :TEMPO_API_RESPONSE
      TEMPO_API_JSON = :TEMPO_API_JSON
    end

    class TempoApiAction < Action
      class << self
        def run(params)
          require 'json'

          http_method = (params[:http_method] || 'GET').to_s.upcase
          url = construct_url(params[:server_url], params[:path], params[:url])
          headers = construct_headers(params[:api_token], params[:headers])
          payload = construct_body(params[:body])
          error_handlers = params[:error_handlers] || {}

          response = call_endpoint(
            url,
            http_method,
            headers,
            payload
          )

          status_code = response[:status]
          result = {
            status: status_code,
            body: response.body || "",
            json: parse_json(response.body) || {}
          }

          if status_code.between?(200, 299)
            yield(result[:json]) if block_given?
          else
            handled_error = error_handlers[status_code] || error_handlers['*']
            if handled_error
              handled_error.call(result)
            else
              UI.user_error!("Tempo responded with #{status_code}\n---\n#{response.body}")
            end
          end

          Actions.lane_context[SharedValues::TEMPO_API_STATUS_CODE] = result[:status]
          Actions.lane_context[SharedValues::TEMPO_API_RESPONSE] = result[:body]
          Actions.lane_context[SharedValues::TEMPO_API_JSON] = result[:json]
        end

        #####################################################
        # @!group Documentation
        #####################################################

        def description
          "Call a Tempo API endpoint and get the resulting JSON response"
        end

        def details
          [
            "Calls any Tempo API endpoint. You must provide your Tempo Personal token.",
            "Out parameters provide the status code and the full response JSON if valid, otherwise the raw response body.",
            "Documentation: [https://tempo-io.github.io/tempo-api-docs/)."
          ].join("\n")
        end

        def available_options
          [
            FastlaneCore::ConfigItem.new(key: :server_url,
                                         env_name: "FL_TEMPO_API_SERVER_URL",
                                         description: "The server url. e.g. 'https://your.internal.tempo.host/api/v3' (Default: 'https://api.tempo.io')",
                                         default_value: "https://api.tempo.io",
                                         optional: true,
                                         verify_block: proc do |value|
                                           UI.user_error!("Please include the protocol in the server url, e.g. https://your.tempo.server/api/v3") unless value.include?("//")
                                         end),
            FastlaneCore::ConfigItem.new(key: :api_token,
                                         env_name: "FL_TEMPO_API_TOKEN",
                                         description: "Personal API Token for Tempo",
                                         sensitive: true,
                                         code_gen_sensitive: true,
                                         is_string: true,
                                         default_value: ENV["TEMPO_API_TOKEN"],
                                         default_value_dynamic: true,
                                         optional: false),
            FastlaneCore::ConfigItem.new(key: :http_method,
                                         env_name: "FL_TEMPO_API_HTTP_METHOD",
                                         description: "The HTTP method. e.g. GET / POST",
                                         default_value: "GET",
                                         optional: true,
                                         verify_block: proc do |value|
                                           unless %w(GET POST PUT DELETE HEAD CONNECT PATCH).include?(value.to_s.upcase)
                                             UI.user_error!("Unrecognised HTTP method")
                                           end
                                         end),
            FastlaneCore::ConfigItem.new(key: :body,
                                         env_name: "FL_TEMPO_API_REQUEST_BODY",
                                         description: "The request body in JSON or hash format",
                                         is_string: false,
                                         default_value: nil,
                                         optional: true),
            FastlaneCore::ConfigItem.new(key: :path,
                                         env_name: "FL_TEMPO_API_PATH",
                                         description: "The endpoint path. e.g. '/core/3/worklogs'",
                                         optional: true),
            FastlaneCore::ConfigItem.new(key: :url,
                                         env_name: "FL_TEMPO_API_URL",
                                         description: "The complete full url - used instead of path. e.g. 'https://api.tempo.io/core/3/worklog...'",
                                         optional: true,
                                         verify_block: proc do |value|
                                           UI.user_error!("Please include the protocol in the url, e.g. https://api.tempo.io") unless value.include?("//")
                                         end),
            FastlaneCore::ConfigItem.new(key: :error_handlers,
                                         description: "Optional error handling hash based on status code, or pass '*' to handle all errors",
                                         is_string: false,
                                         default_value: {},
                                         optional: true),
            FastlaneCore::ConfigItem.new(key: :headers,
                                         description: "Optional headers to apply",
                                         is_string: false,
                                         default_value: {},
                                         optional: true)
          ]
        end

        def output
          [
            ['TEMPO_API_STATUS_CODE', 'The status code returned from the request'],
            ['TEMPO_API_RESPONSE', 'The full response body'],
            ['TEMPO_API_JSON', 'The parsed json returned from Tempo']
          ]
        end

        def return_value
          "A hash including the HTTP status code (:status), the response body (:body), and if valid JSON has been returned the parsed JSON (:json)."
        end

        def authors
          ["crazymanish"]
        end

        def example_code
          [
            'result = tempo_api(
            server_url: "https://api.tempo.io",
            api_token: ENV["TEMPO_TOKEN"],
            http_method: "POST",
            path: "/core/3/worklogs...",
            body: { ref: "master" }
          )',
            '# Alternatively call directly with optional error handling or block usage
            TempoApiAction.run(
              server_url: "https://api.tempo.io",
              api_token: ENV["TEMPO_TOKEN"],
              http_method: "GET",
              path: "/core/3/worklogs...",
              error_handlers: {
                404 => proc do |result|
                  UI.message("Something went wrong - I couldn\'t find it...")
                end,
                \'*\' => proc do |result|
                  UI.message("Handle all error codes other than 404")
                end
              }
            ) do |result|
              UI.message("JSON returned: #{result[:json]}")
            end
          '
          ]
        end

        def is_supported?(platform)
          true
        end

        private

        def construct_headers(api_token, overrides)
          headers = { 'Content-Type' => 'application/json' }
          headers['Authorization'] = "Bearer #{api_token}" if api_token
          headers.merge(overrides || {})
        end

        def construct_url(server_url, path, url)
          return_url = (server_url && path) ? File.join(server_url, path) : url

          UI.user_error!("Please provide either `server_url` (e.g. https://api.tempo.io) and 'path' or full 'url' for Tempo API endpoint") unless return_url

          return_url
        end

        def construct_body(body)
          return body if body.nil?

          body ||= {}

          if body.kind_of?(Hash)
            body.to_json
          elsif body.kind_of?(Array)
            body.to_json
          else
            UI.user_error!("Please provide valid JSON, or a hash as request body") unless parse_json(body)
            body
          end
        end

        def parse_json(value)
          JSON.parse(value)
        rescue JSON::ParserError
          nil
        end

        def call_endpoint(url, http_method, headers, body)
          require 'excon'

          connection = Excon.new(url)
          connection.request(
            method: http_method,
            headers: headers,
            body: body
          )
        end
      end
    end
  end
end
