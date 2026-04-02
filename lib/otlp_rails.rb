require "otlp_rails/version"
require "otlp_rails/configuration"
require "otlp_rails/meter_provider_resolver"
require "otlp_rails/subscriber"
require "otlp_rails/subscribers/action_controller_subscriber"
require "otlp_rails/subscribers/active_record_subscriber"
require "otlp_rails/subscribers/active_job_subscriber"
require "otlp_rails/subscriber_registry"
require "otlp_rails/railtie" if defined?(Rails::Railtie)

module OTLPRails
  class Error < StandardError; end

  class << self
    attr_accessor :meter

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
    end

    def reset!
      @configuration = Configuration.new
      @meter = nil

      SubscriberRegistry.instance.unsubscribe_all
    end

    def subscribe!
      resolver = MeterProviderResolver.new(configuration)
      meter_provider = resolver.resolve

      self.meter = meter_provider.meter(
        "otlp_rails",
        version: VERSION
      )

      SubscriberRegistry.instance.subscribe_all(meter)
    end

    def unsubscribe!
      SubscriberRegistry.instance.unsubscribe_all
    end
  end
end
