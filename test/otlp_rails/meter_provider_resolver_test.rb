require "test_helper"

class MeterProviderResolverTest < Minitest::Test
  include TestHelpers

  def setup
    @config = OTLPRails::Configuration.new
  end

  def teardown
    OpenTelemetry.meter_provider = OpenTelemetry::Metrics::MeterProvider.new
  end

  def test_discovers_existing_sdk_provider_with_readers
    provider, _exporter, _meter = setup_meter_provider
    OpenTelemetry.meter_provider = provider

    resolver = OTLPRails::MeterProviderResolver.new(@config)
    resolved = resolver.resolve

    assert_same provider, resolved
  end

  def test_falls_back_when_provider_is_noop
    OpenTelemetry.meter_provider = OpenTelemetry::Metrics::MeterProvider.new

    resolver = OTLPRails::MeterProviderResolver.new(@config)
    resolved = resolver.resolve

    assert_instance_of OpenTelemetry::SDK::Metrics::MeterProvider, resolved
    refute_instance_of OpenTelemetry::Metrics::MeterProvider, resolved
  end

  def test_falls_back_when_sdk_provider_has_no_readers
    provider = OpenTelemetry::SDK::Metrics::MeterProvider.new
    OpenTelemetry.meter_provider = provider

    resolver = OTLPRails::MeterProviderResolver.new(@config)
    resolved = resolver.resolve

    refute_same provider, resolved
    assert_instance_of OpenTelemetry::SDK::Metrics::MeterProvider, resolved
  end

  def test_standalone_provider_sets_global
    OpenTelemetry.meter_provider = OpenTelemetry::Metrics::MeterProvider.new

    resolver = OTLPRails::MeterProviderResolver.new(@config)
    resolved = resolver.resolve

    assert_same resolved, OpenTelemetry.meter_provider
  end
end
