require "test_helper"

class ManapoolOrderHydrationJobTest < ActiveJob::TestCase
  test "reports rescued hydration failures to monitoring" do
    service = Manapool::OrderHydratorService.singleton_class
    reporter = Monitoring::Reporter.singleton_class

    original_service_call = Manapool::OrderHydratorService.method(:call)
    original_capture_exception = Monitoring::Reporter.method(:capture_exception)

    captured_exception = nil
    captured_context = nil

    service.send(:define_method, :call) do |_order_id|
      raise StandardError, "hydration failed"
    end

    reporter.send(:define_method, :capture_exception) do |exception, **context|
      captured_exception = exception
      captured_context = context
    end

    Manapool::OrderHydrationJob.perform_now(123)

    assert_instance_of StandardError, captured_exception
    assert_equal "manapool.order_hydration", captured_context[:tags][:job]
    assert_equal 123, captured_context[:extra][:order_id]
  ensure
    service.send(:define_method, :call, original_service_call)
    reporter.send(:define_method, :capture_exception, original_capture_exception)
  end
end
