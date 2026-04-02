module OTLPRails
  module Subscribers
    class ActiveRecordSubscriber < Subscriber
      OPERATION_REGEX = /\A\s*(SELECT|INSERT|UPDATE|DELETE)/i
      SKIP_NAMES = ["SCHEMA", "EXPLAIN"].freeze

      def self.events
        ["sql.active_record"]
      end

      def setup_instruments
        @instruments[:query_duration] = meter.create_histogram(
          metric_name("db.query.duration"),
          unit: "ms",
          description: "Duration of SQL queries executed by ActiveRecord"
        )

        @instruments[:query_count] = meter.create_counter(
          metric_name("db.query.count"),
          unit: "queries",
          description: "Total number of SQL queries executed by ActiveRecord"
        )
      end

      def on_event(_name, started, finished, _unique_id, payload)
        return if payload[:name].nil? || payload[:name].to_s.empty?
        return if SKIP_NAMES.include?(payload[:name])
        return if payload[:sql].nil? || payload[:sql].to_s.empty?

        operation = extract_operation(payload[:sql])
        return if !operation

        attributes = {
          "operation" => operation,
          "name" => payload[:name].to_s
        }

        duration = duration_ms(started, finished)

        @instruments[:query_duration].record(duration, attributes: attributes)
        @instruments[:query_count].add(1, attributes: attributes)
      end

      private

      def extract_operation(sql)
        match = sql.match(OPERATION_REGEX)
        match ? match[1].upcase : nil
      end
    end
  end
end
