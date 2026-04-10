require "test_helper"

class ActiveSupportCacheSubscriberTest < Minitest::Test
  include TestHelpers
  include NotificationHelpers

  def setup
    OTLPRails.reset!
    @_provider, @exporter, @meter = setup_meter_provider
    @subscriber = OTLPRails::Subscribers::ActiveSupportCacheSubscriber.new(@meter)
    @subscriber.subscribe!
  end

  def teardown
    @subscriber.unsubscribe!
    OTLPRails.reset!
  end

  def test_events
    assert_equal [
      "cache_read.active_support",
      "cache_write.active_support",
      "cache_delete.active_support"
    ],
      OTLPRails::Subscribers::ActiveSupportCacheSubscriber.events
  end

  def test_records_cache_read_duration
    simulate_cache_read

    snapshots = collect_metrics(@exporter)
    metric = find_metric(snapshots, "rails.cache.operation.duration")

    refute_nil metric, "Expected to find rails.cache.operation.duration metric"

    dp = find_data_point(metric, "operation" => "read")
    refute_nil dp, "Expected to find data point for read operation"
    assert dp.sum >= 0, "Expected duration histogram to have a sum"
    assert_equal 1, dp.count
  end

  def test_records_cache_read_count
    simulate_cache_read
    simulate_cache_read

    snapshots = collect_metrics(@exporter)
    metric = find_metric(snapshots, "rails.cache.operation.count")

    refute_nil metric, "Expected to find rails.cache.operation.count metric"

    dp = find_data_point(metric, "operation" => "read")
    refute_nil dp, "Expected to find data point for read operation"
    assert_equal 2, dp.value
  end

  def test_records_cache_write
    simulate_cache_write

    snapshots = collect_metrics(@exporter)
    metric = find_metric(snapshots, "rails.cache.operation.count")

    refute_nil metric
    dp = find_data_point(metric, "operation" => "write")
    refute_nil dp, "Expected to find data point for write operation"
    assert_equal 1, dp.value
  end

  def test_records_cache_delete
    simulate_cache_delete

    snapshots = collect_metrics(@exporter)
    metric = find_metric(snapshots, "rails.cache.operation.count")

    refute_nil metric
    dp = find_data_point(metric, "operation" => "delete")
    refute_nil dp, "Expected to find data point for delete operation"
    assert_equal 1, dp.value
  end

  def test_cache_read_includes_hit_attribute
    simulate_cache_read(hit: true)

    snapshots = collect_metrics(@exporter)
    metric = find_metric(snapshots, "rails.cache.operation.count")

    dp = find_data_point(metric, "operation" => "read", "hit" => "true")
    refute_nil dp, "Expected to find data point with hit=true"
  end

  def test_cache_read_includes_miss_attribute
    simulate_cache_read(hit: false)

    snapshots = collect_metrics(@exporter)
    metric = find_metric(snapshots, "rails.cache.operation.count")

    dp = find_data_point(metric, "operation" => "read", "hit" => "false")
    refute_nil dp, "Expected to find data point with hit=false"
  end

  def test_real_fetch_does_not_double_count
    store = ActiveSupport::Cache::MemoryStore.new

    store.fetch("k") { "v" }
    store.fetch("k") { "v" }

    snapshots = collect_metrics(@exporter)
    metric = find_metric(snapshots, "rails.cache.operation.count")

    refute_nil metric

    read_dps = metric.data_points.select { |dp| dp.attributes["operation"] == "read" }
    total_reads = read_dps.sum(&:value)

    assert_equal 2, total_reads,
      "Two fetches should yield exactly 2 read increments, got #{total_reads} across data points #{read_dps.map(&:attributes).inspect}"

    miss_dp = find_data_point(metric, "operation" => "read", "hit" => "false")
    hit_dp = find_data_point(metric, "operation" => "read", "hit" => "true")

    refute_nil miss_dp, "Expected a read/miss data point from the first fetch"
    refute_nil hit_dp, "Expected a read/hit data point from the second fetch"
    assert_equal 1, miss_dp.value
    assert_equal 1, hit_dp.value
  end

  def test_includes_store_attribute
    simulate_cache_read(store: "ActiveSupport::Cache::RedisCacheStore")

    snapshots = collect_metrics(@exporter)
    metric = find_metric(snapshots, "rails.cache.operation.count")

    dp = find_data_point(metric, "store" => "ActiveSupport::Cache::RedisCacheStore")
    refute_nil dp, "Expected to find data point with store attribute"
  end

  def test_write_does_not_include_hit_attribute
    simulate_cache_write

    snapshots = collect_metrics(@exporter)
    metric = find_metric(snapshots, "rails.cache.operation.count")

    dp = find_data_point(metric, "operation" => "write")
    refute_nil dp
    assert_nil dp.attributes["hit"], "Expected write operations to not include hit attribute"
  end

  def test_delete_does_not_include_hit_attribute
    simulate_cache_delete

    snapshots = collect_metrics(@exporter)
    metric = find_metric(snapshots, "rails.cache.operation.count")

    dp = find_data_point(metric, "operation" => "delete")
    refute_nil dp
    assert_nil dp.attributes["hit"], "Expected delete operations to not include hit attribute"
  end

  def test_respects_metric_prefix
    @subscriber.unsubscribe!

    OTLPRails.configure { |c| c.metric_prefix = "myapp" }

    subscriber = OTLPRails::Subscribers::ActiveSupportCacheSubscriber.new(@meter)
    subscriber.subscribe!

    simulate_cache_read

    snapshots = collect_metrics(@exporter)
    metric = find_metric(snapshots, "myapp.cache.operation.count")

    refute_nil metric, "Expected to find myapp.cache.operation.count with custom prefix"

    subscriber.unsubscribe!
  end
end
