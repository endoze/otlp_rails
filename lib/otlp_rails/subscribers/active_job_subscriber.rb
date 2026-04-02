module OTLPRails
  module Subscribers
    class ActiveJobSubscriber < Subscriber
      def self.events
        [
          "perform.active_job",
          "enqueue.active_job",
          "enqueue_at.active_job"
        ]
      end

      def setup_instruments
        @instruments[:perform_duration] = meter.create_histogram(
          metric_name("job.perform.duration"),
          unit: "ms",
          description: "Duration of ActiveJob job execution"
        )

        @instruments[:perform_count] = meter.create_counter(
          metric_name("job.perform.count"),
          unit: "jobs",
          description: "Total number of ActiveJob jobs performed"
        )

        @instruments[:enqueue_count] = meter.create_counter(
          metric_name("job.enqueue.count"),
          unit: "jobs",
          description: "Total number of ActiveJob jobs enqueued"
        )
      end

      def on_event(name, started, finished, _unique_id, payload)
        case name
        when "perform.active_job"
          record_perform(started, finished, payload)
        when "enqueue.active_job", "enqueue_at.active_job"
          record_enqueue(payload)
        end
      end

      private

      def record_perform(started, finished, payload)
        job = payload[:job]
        status = payload[:exception_object] ? "error" : "success"

        attributes = {
          "job_class" => job.class.name,
          "queue_name" => job.queue_name.to_s,
          "status" => status
        }

        duration = duration_ms(started, finished)

        @instruments[:perform_duration].record(duration, attributes: attributes)
        @instruments[:perform_count].add(1, attributes: attributes)
      end

      def record_enqueue(payload)
        job = payload[:job]

        attributes = {
          "job_class" => job.class.name,
          "queue_name" => job.queue_name.to_s
        }

        @instruments[:enqueue_count].add(1, attributes: attributes)
      end
    end
  end
end
