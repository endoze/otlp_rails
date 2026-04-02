module OTLPRails
  module Subscribers
    class ActionControllerSubscriber < Subscriber
      def self.events
        ["process_action.action_controller"]
      end

      def setup_instruments
        @instruments[:request_duration] = meter.create_histogram(
          metric_name("http.request.duration"),
          unit: "ms",
          description: "Duration of HTTP requests processed by Rails controllers"
        )

        @instruments[:request_count] = meter.create_counter(
          metric_name("http.request.count"),
          unit: "requests",
          description: "Total number of HTTP requests processed by Rails controllers"
        )
      end

      def on_event(_name, started, finished, _unique_id, payload)
        attributes = {
          "controller" => payload[:controller].to_s,
          "action" => payload[:action].to_s,
          "status" => payload[:status].to_s,
          "method" => payload[:method].to_s
        }

        duration = duration_ms(started, finished)

        @instruments[:request_duration].record(duration, attributes: attributes)
        @instruments[:request_count].add(1, attributes: attributes)
      end
    end
  end
end
