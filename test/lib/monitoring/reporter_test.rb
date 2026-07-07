require "test_helper"

class MonitoringReporterTest < ActiveSupport::TestCase
  ScopeDouble = Struct.new(:tags, :contexts, keyword_init: true) do
    def set_tags(values)
      tags.merge!(values)
    end

    def set_context(key, value)
      contexts[key] = value
    end
  end

  test "capture_exception enriches scope and forwards exception to sentry" do
    sentry = Sentry.singleton_class
    original_with_scope = Sentry.method(:with_scope)
    original_capture_exception = Sentry.method(:capture_exception)

    scope = ScopeDouble.new(tags: {}, contexts: {})
    captured_exception = nil

    sentry.send(:define_method, :with_scope) do |&block|
      block.call(scope)
    end

    sentry.send(:define_method, :capture_exception) do |exception|
      captured_exception = exception
    end

    exception = StandardError.new("boom")

    Monitoring::Reporter.capture_exception(
      exception,
      tags: { component: "test.component" },
      extra: { order_id: 42 },
      message: "captured failure"
    )

    assert_equal exception, captured_exception
    assert_equal({ component: "test.component" }, scope.tags)
    assert_equal(
      { "message" => "captured failure", "order_id" => 42 },
      scope.contexts["monitoring"]
    )
  ensure
    sentry.send(:define_method, :with_scope, original_with_scope)
    sentry.send(:define_method, :capture_exception, original_capture_exception)
  end

  test "log mirrors to rails logger and sentry logger" do
    rails_logger = Object.new
    sentry_logger = Object.new

    rails_messages = []
    sentry_messages = []

    rails_logger.define_singleton_method(:info) { |message| rails_messages << message }
    sentry_logger.define_singleton_method(:info) { |message| sentry_messages << message }

    original_rails_logger = Rails.logger
    original_sentry_logger = Sentry.logger

    Rails.singleton_class.send(:define_method, :logger) { rails_logger }
    Sentry.singleton_class.send(:define_method, :logger) { sentry_logger }

    Monitoring::Reporter.log(
      :info,
      "Webhook received",
      source: "manapool",
      event_type: "order.created"
    )

    assert_equal 1, rails_messages.size
    assert_equal 1, sentry_messages.size
    assert_includes rails_messages.first, "Webhook received"
    assert_includes rails_messages.first, "source=manapool"
    assert_equal rails_messages.first, sentry_messages.first
  ensure
    Rails.singleton_class.send(:define_method, :logger) { original_rails_logger }
    Sentry.singleton_class.send(:define_method, :logger) { original_sentry_logger }
  end
end
