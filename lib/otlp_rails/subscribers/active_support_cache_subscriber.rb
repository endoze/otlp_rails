module OTLPRails
  module Subscribers
    class ActiveSupportCacheSubscriber < Subscriber
      EVENT_OPERATIONS = {
        "cache_read.active_support" => "read",
        "cache_write.active_support" => "write",
        "cache_delete.active_support" => "delete"
      }.freeze

      def self.events
        EVENT_OPERATIONS.keys
      end

      def setup_instruments
        @instruments[:operation_duration] = meter.create_histogram(
          metric_name("cache.operation.duration"),
          unit: "ms",
          description: "Duration of cache operations"
        )

        @instruments[:operation_count] = meter.create_counter(
          metric_name("cache.operation.count"),
          unit: "operations",
          description: "Total number of cache operations"
        )
      end

      def on_event(name, started, finished, _unique_id, payload)
        operation = EVENT_OPERATIONS[name]
        return if operation.nil?

        attributes = {
          "operation" => operation,
          "store" => payload[:store].to_s
        }

        if operation == "read"
          attributes["hit"] = payload[:hit].to_s
        end

        duration = duration_ms(started, finished)

        @instruments[:operation_duration].record(duration, attributes: attributes)
        @instruments[:operation_count].add(1, attributes: attributes)
      end
    end
  end
end
