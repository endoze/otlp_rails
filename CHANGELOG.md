# Changelog

## [0.2.0](https://github.com/endoze/otlp_rails/compare/otlp_rails-v0.1.0...otlp_rails/v0.2.0) (2026-04-03)


### Features

* initial release of otlp_rails ([#7](https://github.com/endoze/otlp_rails/issues/7)) ([45a791b](https://github.com/endoze/otlp_rails/commit/45a791bd3194a0b9172959f581f16ee499dbea09))

## [0.1.0] - Unreleased

- Initial release
- ActionController request metrics (duration histogram, request counter)
- ActiveRecord query metrics (duration histogram, query counter)
- ActiveJob job metrics (perform duration/count, enqueue count)
- Hybrid MeterProvider discovery (reuse existing or provision standalone)
- Pluggable subscriber architecture for custom metrics
- Rails Railtie for zero-config integration
