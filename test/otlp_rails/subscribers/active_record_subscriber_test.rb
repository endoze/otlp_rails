require "test_helper"

class ActiveRecordSubscriberTest < Minitest::Test
  include TestHelpers
  include NotificationHelpers

  def setup
    OTLPRails.reset!
    @_provider, @exporter, @meter = setup_meter_provider
    @subscriber = OTLPRails::Subscribers::ActiveRecordSubscriber.new(@meter)
    @subscriber.subscribe!
  end

  def teardown
    @subscriber.unsubscribe!
    OTLPRails.reset!
  end

  def test_events
    assert_equal ["sql.active_record"],
      OTLPRails::Subscribers::ActiveRecordSubscriber.events
  end

  def test_records_select_query
    simulate_sql_query(sql: "SELECT * FROM users WHERE id = 1", name: "User Load")

    snapshots = collect_metrics(@exporter)
    metric = find_metric(snapshots, "rails.db.query.count")

    refute_nil metric
    dp = find_data_point(metric, "operation" => "SELECT", "name" => "User Load")
    refute_nil dp
    assert_equal 1, dp.value
  end

  def test_records_insert_query
    simulate_sql_query(sql: "INSERT INTO users (name) VALUES ('test')", name: "User Create")

    snapshots = collect_metrics(@exporter)
    metric = find_metric(snapshots, "rails.db.query.count")
    dp = find_data_point(metric, "operation" => "INSERT")

    refute_nil dp
  end

  def test_records_update_query
    simulate_sql_query(sql: "UPDATE users SET name = 'test' WHERE id = 1", name: "User Update")

    snapshots = collect_metrics(@exporter)
    metric = find_metric(snapshots, "rails.db.query.count")
    dp = find_data_point(metric, "operation" => "UPDATE")

    refute_nil dp
  end

  def test_records_delete_query
    simulate_sql_query(sql: "DELETE FROM users WHERE id = 1", name: "User Destroy")

    snapshots = collect_metrics(@exporter)
    metric = find_metric(snapshots, "rails.db.query.count")
    dp = find_data_point(metric, "operation" => "DELETE")

    refute_nil dp
  end

  def test_records_query_duration
    simulate_sql_query(sql: "SELECT 1", name: "Test Query")

    snapshots = collect_metrics(@exporter)
    metric = find_metric(snapshots, "rails.db.query.duration")

    refute_nil metric
    dp = find_data_point(metric, "operation" => "SELECT")
    refute_nil dp
    assert dp.sum >= 0
    assert_equal 1, dp.count
  end

  def test_skips_schema_queries
    simulate_sql_query(sql: "SELECT * FROM information_schema", name: "SCHEMA")

    snapshots = collect_metrics(@exporter)
    metric = find_metric(snapshots, "rails.db.query.count")

    assert_nil metric
  end

  def test_skips_explain_queries
    simulate_sql_query(sql: "EXPLAIN SELECT * FROM users", name: "EXPLAIN")

    snapshots = collect_metrics(@exporter)
    metric = find_metric(snapshots, "rails.db.query.count")

    assert_nil metric
  end

  def test_skips_nil_name
    simulate_sql_query(sql: "SELECT 1", name: nil)

    snapshots = collect_metrics(@exporter)
    metric = find_metric(snapshots, "rails.db.query.count")

    assert_nil metric
  end

  def test_skips_non_crud_sql
    simulate_sql_query(sql: "BEGIN", name: "Transaction")

    snapshots = collect_metrics(@exporter)
    metric = find_metric(snapshots, "rails.db.query.count")

    assert_nil metric
  end
end
