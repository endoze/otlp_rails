require "test_helper"

class ConfigurationTest < Minitest::Test
  def setup
    @config = OTLPRails::Configuration.new
  end

  def test_default_metric_prefix
    assert_equal "rails", @config.metric_prefix
  end

  def test_default_otlp_endpoint
    assert_nil @config.otlp_endpoint
  end

  def test_default_export_interval
    assert_equal 60_000, @config.export_interval_millis
  end

  def test_default_export_timeout
    assert_equal 30_000, @config.export_timeout_millis
  end

  def test_default_resource_attributes
    assert_equal({}, @config.resource_attributes)
  end

  def test_all_built_in_subscribers_enabled_by_default
    assert @config.subscriber_enabled?(:action_controller)
    assert @config.subscriber_enabled?(:active_record)
    assert @config.subscriber_enabled?(:active_job)
  end

  def test_disable_subscriber
    @config.disable_subscriber(:active_record)
    refute @config.subscriber_enabled?(:active_record)
    assert @config.subscriber_enabled?(:action_controller)
  end

  def test_enable_subscriber
    @config.disable_subscriber(:active_record)
    @config.enable_subscriber(:active_record)
    assert @config.subscriber_enabled?(:active_record)
  end

  def test_disable_unknown_subscriber_is_noop
    @config.disable_subscriber(:unknown)
    assert @config.subscriber_enabled?(:action_controller)
  end

  def test_add_custom_subscriber
    klass = Class.new
    @config.add_subscriber(klass)
    assert_includes @config.custom_subscribers, klass
  end

  def test_custom_subscribers_empty_by_default
    assert_empty @config.custom_subscribers
  end

  def test_set_metric_prefix
    @config.metric_prefix = "myapp"
    assert_equal "myapp", @config.metric_prefix
  end

  def test_set_resource_attributes
    @config.resource_attributes = {"env" => "test"}
    assert_equal({"env" => "test"}, @config.resource_attributes)
  end
end
