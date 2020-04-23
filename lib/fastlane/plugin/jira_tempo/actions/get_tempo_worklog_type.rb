require 'fastlane/action'
require_relative '../helper/jira_tempo_helper'

module Fastlane
  module Actions
    module SharedValues
      GET_TEMPO_WORKLOG_TYPE_RESULT = :GET_TEMPO_WORKLOG_TYPE_RESULT
    end

    class GetTempoWorklogTypeAction < Action
      def self.run(params)
        TempoApiAction.run(
          server_url: "https://api.tempo.io",
          api_token: params[:api_token],
          path: "/core/3/accounts",
          error_handlers: {
            '*' => proc do |result|
              UI.error(result)
              return nil
            end
          }
        ) do |result|
          require 'terminal-table'

          types = result["results"].map { |log| [log["key"], log["name"]] }
          table = Terminal::Table.new(title: "Tempo worklog type", headings: ['Type', 'Details'], rows: types)
          puts table

          Actions.lane_context[SharedValues::GET_TEMPO_WORKLOG_TYPE_RESULT] = result
          return result
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Get Tempo worklog_type information"
      end

      def self.details
        "It will Tempo worklog_type information based on user account"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :api_token,
                                       env_name: "FL_GET_TEMPO_WORKLOG_TYPE_API_TOKEN",
                                       description: "Personal API Token for Tempo",
                                       sensitive: true,
                                       code_gen_sensitive: true,
                                       default_value: ENV["TEMPO_API_TOKEN"],
                                       default_value_dynamic: true,
                                       optional: true)
        ]
      end

      def self.output
        [
          ['GET_TEMPO_WORKLOG_TYPE_RESULT', 'Get worklog_type api response result']
        ]
      end

      def self.return_value
        "Returns Tempo worklog_type information"
      end

      def self.authors
        ["crazymanish"]
      end

      def self.example_code
        [
          'get_tempo_worklog_type',
          'get_tempo_worklog_type(api_token: "some_token")'
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
