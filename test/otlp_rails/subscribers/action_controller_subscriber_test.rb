require "test_helper"

class ActionControllerSubscriberTest < Minitest::Test
  include TestHelpers
  include NotificationHelpers

  def setup
    OTLPRails.reset!
    @_provider, @exporter, @meter = setup_meter_provider
    @subscriber = OTLPRails::Subscribers::ActionControllerSubscriber.new(@meter)
    @subscriber.subscribe!
  end

  def teardown
    @subscriber.unsubscribe!
    OTLPRails.reset!
  end

  def test_events
    assert_equal ["process_action.action_controller"],
      OTLPRails::Subscribers::ActionControllerSubscriber.events
  end

  def test_records_request_duration
    simulate_controller_request(controller: "UsersController", action: "show", status: 200, method: "GET")

    snapshots = collect_metrics(@exporter)
    metric = find_metric(snapshots, "rails.http.request.duration")

    refute_nil metric, "Expected to find rails.http.request.duration metric"

    dp = find_data_point(metric, "controller" => "UsersController", "action" => "show")
    refute_nil dp, "Expected to find data point for UsersController#show"
    assert dp.sum >= 0, "Expected duration histogram to have a sum"
    assert dp.count == 1, "Expected exactly one observation"
  end

  def test_records_request_count
    simulate_controller_request(controller: "UsersController", action: "index", status: 200, method: "GET")
    simulate_controller_request(controller: "UsersController", action: "index", status: 200, method: "GET")

    snapshots = collect_metrics(@exporter)
    metric = find_metric(snapshots, "rails.http.request.count")

    refute_nil metric, "Expected to find rails.http.request.count metric"

    dp = find_data_point(metric, "controller" => "UsersController", "action" => "index")
    refute_nil dp, "Expected to find data point for UsersController#index"
    assert_equal 2, dp.value
  end

  def test_includes_status_attribute
    simulate_controller_request(status: 404)

    snapshots = collect_metrics(@exporter)
    metric = find_metric(snapshots, "rails.http.request.count")
    dp = find_data_point(metric, "status" => "404")

    refute_nil dp, "Expected to find data point with status 404"
  end

  def test_includes_method_attribute
    simulate_controller_request(method: "POST")

    snapshots = collect_metrics(@exporter)
    metric = find_metric(snapshots, "rails.http.request.count")
    dp = find_data_point(metric, "method" => "POST")

    refute_nil dp, "Expected to find data point with method POST"
  end

  def test_respects_metric_prefix
    OTLPRails.configure { |c| c.metric_prefix = "myapp" }

    subscriber = OTLPRails::Subscribers::ActionControllerSubscriber.new(@meter)
    subscriber.subscribe!

    simulate_controller_request

    snapshots = collect_metrics(@exporter)
    metric = find_metric(snapshots, "myapp.http.request.count")

    refute_nil metric, "Expected to find myapp.http.request.count with custom prefix"

    subscriber.unsubscribe!
  end
end
