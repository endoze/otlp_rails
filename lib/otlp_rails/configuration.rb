module OTLPRails
  class Configuration
    attr_accessor :metric_prefix,
      :otlp_endpoint,
      :export_interval_millis,
      :export_timeout_millis,
      :resource_attributes

    attr_reader :subscriber_settings, :custom_subscribers

    def initialize
      @metric_prefix = "rails"
      @otlp_endpoint = nil
      @export_interval_millis = 60_000
      @export_timeout_millis = 30_000
      @resource_attributes = {}

      @subscriber_settings = {
        action_controller: {enabled: true},
        active_record: {enabled: true},
        active_job: {enabled: true},
        active_support_cache: {enabled: true}
      }

      @custom_subscribers = []
    end

    def enable_subscriber(name)
      @subscriber_settings[name][:enabled] = true if @subscriber_settings.key?(name)
    end

    def disable_subscriber(name)
      @subscriber_settings[name][:enabled] = false if @subscriber_settings.key?(name)
    end

    def subscriber_enabled?(name)
      @subscriber_settings.dig(name, :enabled) != false
    end

    def add_subscriber(subscriber_class)
      @custom_subscribers << subscriber_class
    end
  end
end
