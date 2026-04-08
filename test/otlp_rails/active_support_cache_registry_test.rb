require "test_helper"

class ActiveSupportCacheRegistryTest < Minitest::Test
  include TestHelpers
  include NotificationHelpers

  def setup
    OTLPRails.reset!
  end

  def teardown
    OTLPRails::SubscriberRegistry.instance.unsubscribe_all
    OTLPRails.reset!
  end

  def test_active_support_cache_subscriber_is_registered
    assert OTLPRails::SubscriberRegistry::BUILT_IN_SUBSCRIBERS.key?(:active_support_cache)
  end

  def test_active_support_cache_enabled_by_default
    assert OTLPRails.configuration.subscriber_enabled?(:active_support_cache)
  end

  def test_active_support_cache_can_be_disabled
    OTLPRails.configure { |c| c.disable_subscriber(:active_support_cache) }
    refute OTLPRails.configuration.subscriber_enabled?(:active_support_cache)
  end

  def test_subscribe_all_includes_cache_subscriber
    _provider, exporter, meter = setup_meter_provider
    OTLPRails::SubscriberRegistry.instance.subscribe_all(meter)

    simulate_cache_read

    snapshots = collect_metrics(exporter)
    metric = find_metric(snapshots, "rails.cache.operation.count")

    refute_nil metric, "Expected cache subscriber to be active after subscribe_all"
  end
end
