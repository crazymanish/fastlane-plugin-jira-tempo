module Fastlane
  module Actions
    module SharedValues
      CREATE_TEMPO_WORKLOG_RESULT = :CREATE_TEMPO_WORKLOG_RESULT
    end

    class CreateTempoWorklogAction < Action
      def self.run(params)
        ticket = params[:ticket]
        time_in_hours = params[:time]
        time_in_hours = time_in_hours.sub('h', '') if time_in_hours.include?("h")
        time_in_seconds = time_in_hours.to_f * 3600

        if params[:date]
          date = params[:date]
        else
          if UI.confirm("Are you logging time for \"today\"? ")
            date = Date.today.to_s
          else
            date = params[:date]
          end
        end

        payload = {
          issueKey: ticket,
          timeSpentSeconds: time_in_seconds,
          billableSeconds: time_in_seconds,
          startDate: date,
          startTime: "00:00:00",
          description: "Spent time on ticket #{ticket}",
          authorAccountId: params[:account_id],
          attributes: [
            params[:attributes]
          ]
        }

        TempoApiAction.run(
          http_method: "POST",
          server_url: "https://api.tempo.io",
          api_token: params[:tempo_api_token],
          path: "/core/3/worklogs",
          body: payload,
          error_handlers: {
            '*' => proc do |result|
              UI.error(result)
              return nil
            end
          }
        ) do |result|
          time = "#{result["timeSpentSeconds"]}|#{result["timeSpentSeconds"]/3600}h"
          ticket = result["issue"]["key"]
          UI.success("Successfully logged \"#{time} time\" in \"#{ticket}\" for \"#{result["startDate"]}\" date 🚀🍻")

          Actions.lane_context[SharedValues::CREATE_TEMPO_WORKLOG_RESULT] = result
          return result
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Create a new worklog in tempo"
      end

      def self.details
        "Create a new worklog in tempo"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :tempo_api_token,
                                       env_name: "FL_CREATE_TEMPO_WORKLOG_API_TOKEN",
                                       description: "Personal API Token for Tempo",
                                       sensitive: true,
                                       code_gen_sensitive: true,
                                       default_value: ENV["TEMPO_API_TOKEN"],
                                       default_value_dynamic: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :account_id,
                                       env_name: "FL_CREATE_TEMPO_WORKLOG_ACCOUNT_ID",
                                       description: "Personal account id for Tempo",
                                       sensitive: true,
                                       code_gen_sensitive: true,
                                       default_value: ENV["TEMPO_ACCOUNT_ID"],
                                       default_value_dynamic: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :ticket,
                                       env_name: "FL_CREATE_TEMPO_WORKLOG_TICKET",
                                       description: "Provide JIRA ticket i.e PRJ-1000 or WI-1000",
                                       is_string: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :time,
                                       env_name: "FL_CREATE_TEMPO_WORKLOG_TIME",
                                       description: "Provide Time spent in hours i.e 2 or 2h",
                                       is_string: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :date,
                                       env_name: "FL_CREATE_TEMPO_WORKLOG_DATE",
                                       description: "Provide date i.e  2020-04-23",
                                       is_string: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :attributes,
                                       env_name: "FL_CREATE_TEMPO_WORKLOG_ATTRIBUTES",
                                       description: "Optional attributes hash for Tempo",
                                       is_string: false,
                                       default_value: {},
                                       optional: true)
        ]
      end

      def self.output
        [
          ['CREATE_TEMPO_WORKLOG_RESULT', 'Newly created worklog response result']
        ]
      end

      def self.return_value
        "Newly created worklog response"
      end

      def self.authors
        ["crazymanish"]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
