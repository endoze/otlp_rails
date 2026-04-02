require "test_helper"

class ActiveJobSubscriberTest < Minitest::Test
  include TestHelpers
  include NotificationHelpers

  def setup
    OTLPRails.reset!
    @_provider, @exporter, @meter = setup_meter_provider
    @subscriber = OTLPRails::Subscribers::ActiveJobSubscriber.new(@meter)
    @subscriber.subscribe!
  end

  def teardown
    @subscriber.unsubscribe!
    OTLPRails.reset!
  end

  def test_events
    assert_equal ["perform.active_job", "enqueue.active_job", "enqueue_at.active_job"],
      OTLPRails::Subscribers::ActiveJobSubscriber.events
  end

  def test_records_successful_perform
    simulate_job_perform(job_class: "WeatherJob", queue: "default")

    snapshots = collect_metrics(@exporter)
    count_metric = find_metric(snapshots, "rails.job.perform.count")

    refute_nil count_metric
    dp = find_data_point(count_metric, "job_class" => "WeatherJob", "status" => "success")
    refute_nil dp
    assert_equal 1, dp.value
  end

  def test_records_failed_perform
    simulate_job_perform(job_class: "WeatherJob", error: true)

    snapshots = collect_metrics(@exporter)
    count_metric = find_metric(snapshots, "rails.job.perform.count")

    refute_nil count_metric
    dp = find_data_point(count_metric, "status" => "error")
    refute_nil dp
    assert_equal 1, dp.value
  end

  def test_records_perform_duration
    simulate_job_perform(job_class: "WeatherJob")

    snapshots = collect_metrics(@exporter)
    metric = find_metric(snapshots, "rails.job.perform.duration")

    refute_nil metric
    dp = find_data_point(metric, "job_class" => "WeatherJob")
    refute_nil dp
    assert dp.sum >= 0
    assert_equal 1, dp.count
  end

  def test_records_enqueue
    simulate_job_enqueue(job_class: "WeatherJob", queue: "default")

    snapshots = collect_metrics(@exporter)
    metric = find_metric(snapshots, "rails.job.enqueue.count")

    refute_nil metric
    dp = find_data_point(metric, "job_class" => "WeatherJob", "queue_name" => "default")
    refute_nil dp
    assert_equal 1, dp.value
  end

  def test_records_enqueue_at
    simulate_job_enqueue(job_class: "WeatherJob", event: "enqueue_at.active_job")

    snapshots = collect_metrics(@exporter)
    metric = find_metric(snapshots, "rails.job.enqueue.count")

    refute_nil metric
    dp = find_data_point(metric, "job_class" => "WeatherJob")
    refute_nil dp
  end

  def test_includes_queue_name_attribute
    simulate_job_perform(job_class: "WeatherJob", queue: "critical")

    snapshots = collect_metrics(@exporter)
    metric = find_metric(snapshots, "rails.job.perform.count")
    dp = find_data_point(metric, "queue_name" => "critical")

    refute_nil dp
  end
end
