require 'fastlane/action'
require_relative '../helper/jira_tempo_helper'

module Fastlane
  module Actions
    module SharedValues
      GET_TEMPO_WORKLOG_RESULT = :GET_TEMPO_WORKLOG_RESULT
    end

    class GetTempoWorklogAction < Action
      def self.run(params)
        path = "/core/3/worklogs"
        path = path + "?issue=#{params[:ticket]}" if params[:ticket]

        TempoApiAction.run(
          server_url: "https://api.tempo.io",
          api_token: params[:api_token],
          path: path,
          error_handlers: {
            '*' => proc do |result|
              UI.error(result)
              return nil
            end
          }
        ) do |result|
          require 'terminal-table'

          logs = result["results"].sort_by { |log| log["startDate"] }.map { |log| [log["tempoWorklogId"], log["issue"]["key"], log["startDate"], "#{log["timeSpentSeconds"]}|#{log["timeSpentSeconds"]/3600}h"] }
          table = Terminal::Table.new(title: "Tempo logs", headings: ['Tempo Id', 'Ticket', 'Start date', 'Time (in s|h)'], rows: logs)
          puts table

          Actions.lane_context[SharedValues::GET_TEMPO_WORKLOG_RESULT] = result
          return result
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Get Tempo ticket worklogs information"
      end

      def self.details
        "It will return all the worklogs information for a specific Tempo ticket"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :api_token,
                                       env_name: "FL_GET_TEMPO_WORKLOG_API_TOKEN",
                                       description: "Personal API Token for Tempo",
                                       sensitive: true,
                                       code_gen_sensitive: true,
                                       default_value: ENV["TEMPO_API_TOKEN"],
                                       default_value_dynamic: true,
                                       optional: true),
           FastlaneCore::ConfigItem.new(key: :ticket,
                                        env_name: "FL_GET_TEMPO_WORKLOG_TICKET",
                                        description: "Provide Tempo ticket i.e PRJ-1000 or WI-1000",
                                        is_string: true,
                                        default_value: nil,
                                        optional: true)
        ]
      end

      def self.output
        [
          ['GET_TEMPO_WORKLOG_RESULT', 'Get worklog api response result']
        ]
      end

      def self.return_value
        "Returns Tempo ticket worklogs information"
      end

      def self.authors
        ["crazymanish"]
      end

      def self.example_code
        [
          'get_tempo_worklog',
          'get_tempo_worklog(ticket: "PRJ-1000")',
          'get_tempo_worklog(
            ticket: "PRJ-1000",
            api_token: "some_token")'
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
