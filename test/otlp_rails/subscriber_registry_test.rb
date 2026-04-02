require "test_helper"

class SubscriberRegistryTest < Minitest::Test
  include TestHelpers

  def setup
    OTLPRails.reset!
    @_provider, @exporter, @meter = setup_meter_provider
  end

  def teardown
    OTLPRails::SubscriberRegistry.instance.unsubscribe_all
    OTLPRails.reset!
  end

  def test_subscribes_all_built_in_by_default
    registry = OTLPRails::SubscriberRegistry.instance
    registry.subscribe_all(@meter)

    assert_equal 3, registry.instance_variable_get(:@active_subscribers).size
  end

  def test_skips_disabled_subscriber
    OTLPRails.configure do |config|
      config.disable_subscriber(:active_record)
    end

    registry = OTLPRails::SubscriberRegistry.instance
    registry.subscribe_all(@meter)

    subscribers = registry.instance_variable_get(:@active_subscribers)
    assert_equal 2, subscribers.size
    refute subscribers.any? { |s| s.is_a?(OTLPRails::Subscribers::ActiveRecordSubscriber) }
  end

  def test_includes_custom_subscribers
    custom_class = Class.new(OTLPRails::Subscriber) do
      def self.events
        ["custom.event"]
      end

      def setup_instruments
        @instruments[:counter] = meter.create_counter("custom.counter")
      end

      def on_event(name, started, finished, unique_id, payload)
      end
    end

    OTLPRails.configure do |config|
      config.add_subscriber(custom_class)
    end

    registry = OTLPRails::SubscriberRegistry.instance
    registry.subscribe_all(@meter)

    subscribers = registry.instance_variable_get(:@active_subscribers)
    assert_equal 4, subscribers.size
    assert subscribers.any? { |s| s.is_a?(custom_class) }
  end

  def test_unsubscribe_all_clears_subscribers
    registry = OTLPRails::SubscriberRegistry.instance
    registry.subscribe_all(@meter)
    registry.unsubscribe_all

    assert_empty registry.instance_variable_get(:@active_subscribers)
  end
end
