require_relative "lib/otlp_rails/version"

Gem::Specification.new do |spec|
  spec.name = "otlp_rails"
  spec.version = OTLPRails::VERSION
  spec.authors = ["Endoze"]
  spec.summary = "Rails ActiveSupport::Notifications to OpenTelemetry metrics via OTLP push"
  spec.description = "Subscribes to Rails instrumentation events and records OpenTelemetry " \
    "metrics, pushing them via OTLP. Works standalone or alongside an existing " \
    "OpenTelemetry SDK setup."
  spec.homepage = "https://github.com/endoze/otlp_rails"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.files = Dir["lib/**/*", "LICENSE.txt", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "railties", ">= 7.0"
  spec.add_dependency "activesupport", ">= 7.0"
  spec.add_dependency "opentelemetry-api", "~> 1.0"
  spec.add_dependency "opentelemetry-metrics-api", "~> 0.2"
  spec.add_dependency "opentelemetry-sdk", "~> 1.0"
  spec.add_dependency "opentelemetry-metrics-sdk", "~> 0.12"
  spec.add_dependency "opentelemetry-exporter-otlp-metrics", "~> 0.7"
end
