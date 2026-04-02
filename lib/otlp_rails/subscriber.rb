module OTLPRails
  class Subscriber
    attr_reader :meter, :subscriptions

    def initialize(meter)
      @meter = meter
      @instruments = {}
      @subscriptions = []
      setup_instruments
    end

    def self.events
      raise NotImplementedError, "#{name} must implement .events"
    end

    def setup_instruments
      raise NotImplementedError, "#{self.class.name} must implement #setup_instruments"
    end

    def on_event(name, started, finished, unique_id, payload)
      raise NotImplementedError, "#{self.class.name} must implement #on_event"
    end

    def subscribe!
      return if self.class.events.none?

      self.class.events.each do |event_name|
        subscription = ActiveSupport::Notifications.subscribe(event_name) do |name, started, finished, unique_id, payload|
          on_event(name, started, finished, unique_id, payload)
        rescue => e
          if !defined?(Rails) || !Rails.respond_to?(:logger) || !Rails.logger
            next
          end

          Rails.logger.warn(
            "[otlp_rails] Error in #{self.class.name} " \
            "handling #{name}: #{e.message}"
          )
        end
        @subscriptions << subscription
      end
    end

    def unsubscribe!
      @subscriptions.each do |subscription|
        ActiveSupport::Notifications.unsubscribe(subscription)
      end
      @subscriptions.clear
    end

    private

    def duration_ms(started, finished)
      (finished - started) * 1000.0
    end

    def metric_name(suffix)
      prefix = OTLPRails.configuration.metric_prefix
      "#{prefix}.#{suffix}"
    end
  end
end
