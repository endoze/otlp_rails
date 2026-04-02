module NotificationHelpers
  def simulate_controller_request(controller: "UsersController", action: "index", status: 200, method: "GET", duration: 0.05)
    payload = {
      controller: controller,
      action: action,
      status: status,
      method: method,
      format: :html,
      path: "/users"
    }

    Process.clock_gettime(Process::CLOCK_MONOTONIC)

    ActiveSupport::Notifications.instrument("process_action.action_controller", payload) do
      # simulate work
    end
  end

  def simulate_sql_query(sql: "SELECT * FROM users", name: "User Load", duration: 0.01)
    payload = {
      sql: sql,
      name: name,
      connection: nil,
      binds: [],
      type_casted_binds: []
    }

    ActiveSupport::Notifications.instrument("sql.active_record", payload) do
      # simulate work
    end
  end

  def simulate_job_perform(job_class: "TestJob", queue: "default", error: false)
    job = Minitest::Mock.new
    job.expect(:class, build_job_class(job_class))
    job.expect(:queue_name, queue)

    payload = {job: job}
    payload[:exception_object] = RuntimeError.new("boom") if error

    ActiveSupport::Notifications.instrument("perform.active_job", payload) do
      # simulate work
    end
  end

  def simulate_job_enqueue(job_class: "TestJob", queue: "default", event: "enqueue.active_job")
    job = Minitest::Mock.new
    job.expect(:class, build_job_class(job_class))
    job.expect(:queue_name, queue)

    payload = {job: job}

    ActiveSupport::Notifications.instrument(event, payload) do
      # simulate work
    end
  end

  private

  def build_job_class(name)
    klass = Class.new
    klass.define_singleton_method(:name) { name }
    klass
  end
end
