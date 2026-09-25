# frozen_string_literal: true

require "active_support"
require "active_support/notifications"
require "sentry-ruby"
require "sentry-rails"
require_relative "../../../../lib/monitoring/request_context"
require_relative "../../../../lib/monitoring/log_subscribers/active_record_subscriber"

RSpec.describe Monitoring::LogSubscribers::ActiveRecordSubscriber do
  let(:subscriber) { described_class.new }
  let(:logger) { instance_double(Sentry::StructuredLogger) }

  before do
    allow(Sentry).to receive(:initialized?).and_return(true)
    allow(Sentry).to receive(:logger).and_return(logger)
    allow(logger).to receive(:info)

    Monitoring::RequestContext.request_id = "req-123"
    Monitoring::RequestContext.controller = "OrdersController"
    Monitoring::RequestContext.action = "edit"
    Monitoring::RequestContext.method = "GET"
    Monitoring::RequestContext.path = "/orders/1/edit"
  end

  after do
    Monitoring::RequestContext.reset
  end

  it "logs sql events with request linkage and statement details" do
    connection = instance_double("Connection")
    pool = instance_double("Pool")
    db_config = instance_double("DbConfig")
    allow(connection).to receive(:pool).and_return(pool)
    allow(pool).to receive(:db_config).and_return(db_config)
    allow(db_config).to receive(:configuration_hash).and_return(
      adapter: "postgresql",
      database: "iron_tusk_toolbox_production",
      host: "db.internal",
      port: 5432
    )

    event = ActiveSupport::Notifications::Event.new(
      "sql.active_record",
      Time.now,
      Time.now + 0.018,
      "txn-2",
      {
        name: "Order Load",
        sql: "SELECT * FROM orders WHERE id = $1",
        cached: false,
        connection: connection
      }
    )

    subscriber.sql(event)

    expect(logger).to have_received(:info).with(
      "Database query: Order Load",
      hash_including(
        statement_name: "Order Load",
        sql: "SELECT * FROM orders WHERE id = $1",
        cached: false,
        db_system: "postgresql",
        db_name: "iron_tusk_toolbox_production",
        server_address: "db.internal",
        server_port: 5432,
        request_id: "req-123",
        controller: "OrdersController",
        action: "edit",
        method: "GET",
        path: "/orders/1/edit",
        duration_ms: be_a(Float),
        origin: "auto.log.rails.log_subscriber"
      )
    )
  end
end
