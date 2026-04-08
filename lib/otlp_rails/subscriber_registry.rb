require "singleton"

module OTLPRails
  class SubscriberRegistry
    include Singleton

    BUILT_IN_SUBSCRIBERS = {
      action_controller: Subscribers::ActionControllerSubscriber,
      active_record: Subscribers::ActiveRecordSubscriber,
      active_job: Subscribers::ActiveJobSubscriber,
      active_support_cache: Subscribers::ActiveSupportCacheSubscriber
    }.freeze

    def initialize
      @active_subscribers = []
    end

    def subscribe_all(meter)
      config = OTLPRails.configuration

      BUILT_IN_SUBSCRIBERS.each do |name, klass|
        next if !config.subscriber_enabled?(name)

        subscriber = klass.new(meter)
        subscriber.subscribe!
        @active_subscribers << subscriber
      end

      config.custom_subscribers.each do |klass|
        subscriber = klass.new(meter)
        subscriber.subscribe!
        @active_subscribers << subscriber
      end
    end

    def unsubscribe_all
      @active_subscribers.each(&:unsubscribe!)
      @active_subscribers.clear
    end
  end
end
