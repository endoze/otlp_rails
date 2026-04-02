# Changelog

## [0.1.0] - Unreleased

- Initial release
- ActionController request metrics (duration histogram, request counter)
- ActiveRecord query metrics (duration histogram, query counter)
- ActiveJob job metrics (perform duration/count, enqueue count)
- Hybrid MeterProvider discovery (reuse existing or provision standalone)
- Pluggable subscriber architecture for custom metrics
- Rails Railtie for zero-config integration
