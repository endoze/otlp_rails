$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "active_support"
require "active_support/notifications"
require "opentelemetry-metrics-sdk"
require "otlp_rails"

Dir[File.expand_path("support/**/*.rb", __dir__)].each { |f| require f }

module TestHelpers
  def setup_meter_provider
    exporter = OpenTelemetry::SDK::Metrics::Export::InMemoryMetricPullExporter.new
    provider = OpenTelemetry::SDK::Metrics::MeterProvider.new
    provider.add_metric_reader(exporter)

    meter = provider.meter("test", version: "0.0.1")

    [provider, exporter, meter]
  end

  def collect_metrics(exporter)
    exporter.pull
    exporter.metric_snapshots
  end

  def find_metric(snapshots, name)
    snapshots.flatten.find { |m| m.name == name }
  end

  def find_data_point(metric, attributes = {})
    metric&.data_points&.find do |dp|
      attributes.all? { |k, v| dp.attributes[k] == v }
    end
  end
end
