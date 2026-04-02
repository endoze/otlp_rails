# Changelog

## [0.3.0](https://github.com/endoze/otlp_rails/compare/otlp_rails-v0.2.0...otlp_rails/v0.3.0) (2026-04-02)


### Features

* initial release of otlp_rails ([#2](https://github.com/endoze/otlp_rails/issues/2)) ([9cc7264](https://github.com/endoze/otlp_rails/commit/9cc7264fbcc364e7c7b97480297e24aabdc91216))

## [0.2.0](https://github.com/endoze/otlp_rails/compare/otlp_rails-v0.1.0...otlp_rails/v0.2.0) (2026-04-02)


### Features

* initial release of otlp_rails ([#2](https://github.com/endoze/otlp_rails/issues/2)) ([9cc7264](https://github.com/endoze/otlp_rails/commit/9cc7264fbcc364e7c7b97480297e24aabdc91216))

## [0.1.0] - Unreleased

- Initial release
- ActionController request metrics (duration histogram, request counter)
- ActiveRecord query metrics (duration histogram, query counter)
- ActiveJob job metrics (perform duration/count, enqueue count)
- Hybrid MeterProvider discovery (reuse existing or provision standalone)
- Pluggable subscriber architecture for custom metrics
- Rails Railtie for zero-config integration
