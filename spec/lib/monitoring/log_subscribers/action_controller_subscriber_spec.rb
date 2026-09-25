# frozen_string_literal: true

require "active_support"
require "active_support/notifications"
require "sentry-ruby"
require "sentry-rails"
require_relative "../../../../lib/monitoring/request_context"
require_relative "../../../../lib/monitoring/log_subscribers/action_controller_subscriber"

RSpec.describe Monitoring::LogSubscribers::ActionControllerSubscriber do
  let(:subscriber) { described_class.new }
  let(:logger) { instance_double(Sentry::StructuredLogger) }

  before do
    configuration = instance_double("SentryConfiguration", send_default_pii: false)
    allow(Sentry).to receive(:initialized?).and_return(true)
    allow(Sentry).to receive(:logger).and_return(logger)
    allow(Sentry).to receive(:configuration).and_return(configuration)
    allow(logger).to receive(:info)
    allow(logger).to receive(:warn)
    allow(logger).to receive(:error)
  end

  it "logs request metadata and timings for controller events" do
    event = ActiveSupport::Notifications::Event.new(
      "process_action.action_controller",
      Time.now,
      Time.now + 0.125,
      "txn-1",
      {
        controller: "OrdersController",
        action: "edit",
        method: "GET",
        path: "/orders/1/edit",
        format: :html,
        status: 200,
        db_runtime: 12.34,
        view_runtime: 45.67,
        request_id: "req-123"
      }
    )

    subscriber.process_action(event)

    expect(logger).to have_received(:info).with(
      "GET /orders/1/edit OrdersController#edit",
      hash_including(
        controller: "OrdersController",
        action: "edit",
        method: "GET",
        path: "/orders/1/edit",
        format: :html,
        status: 200,
        request_id: "req-123",
        db_runtime_ms: 12.34,
        view_runtime_ms: 45.67,
        duration_ms: be_a(Float),
        origin: "auto.log.rails.log_subscriber"
      )
    )
  end
end
