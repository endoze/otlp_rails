require "opentelemetry-metrics-api"

module OTLPRails
  class MeterProviderResolver
    def initialize(configuration)
      @configuration = configuration
    end

    def resolve
      existing = detect_existing_provider
      return existing if existing

      provision_standalone_provider
    end

    private

    def detect_existing_provider
      provider = OpenTelemetry.meter_provider

      return if !provider.is_a?(OpenTelemetry::SDK::Metrics::MeterProvider)
      return if provider.metric_readers.none?

      log(:info,
        "Discovered existing SDK MeterProvider " \
        "with #{provider.metric_readers.size} reader(s); reusing it.")

      provider
    rescue NameError
      nil
    end

    def provision_standalone_provider
      require "opentelemetry/sdk"
      require "opentelemetry-metrics-sdk"
      require "opentelemetry/exporter/otlp_metrics"

      resource = build_resource
      provider = OpenTelemetry::SDK::Metrics::MeterProvider.new(resource: resource)

      exporter_opts = {}
      exporter_opts[:endpoint] = @configuration.otlp_endpoint if @configuration.otlp_endpoint
      exporter = OpenTelemetry::Exporter::OTLP::Metrics::MetricsExporter.new(**exporter_opts)

      periodic_reader = OpenTelemetry::SDK::Metrics::Export::PeriodicMetricReader.new(
        exporter: exporter,
        export_interval_millis: @configuration.export_interval_millis,
        export_timeout_millis: @configuration.export_timeout_millis
      )
      provider.add_metric_reader(periodic_reader)

      OpenTelemetry.meter_provider = provider

      log(:info,
        "Provisioned standalone MeterProvider " \
        "exporting to #{@configuration.otlp_endpoint || "default OTLP endpoint"}.")

      provider
    end

    def log(level, message)
      Rails.logger.send(level, "[otlp_rails] #{message}") if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
    end

    def build_resource
      attrs = {
        "service.name" => ENV.fetch("OTEL_SERVICE_NAME", "rails-app")
      }.merge(@configuration.resource_attributes)

      OpenTelemetry::SDK::Resources::Resource.create(attrs)
    end
  end
end
