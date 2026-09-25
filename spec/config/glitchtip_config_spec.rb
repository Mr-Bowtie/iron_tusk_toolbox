# frozen_string_literal: true

require "spec_helper"

RSpec.describe "GlitchTip configuration" do
  let(:root) { Pathname.new(File.expand_path("../..", __dir__)) }
  let(:gemfile) { root.join("Gemfile").read }
  let(:initializer) { root.join("config/initializers/sentry.rb").read }

  it "loads the official Sentry Rails SDK" do
    expect(gemfile).to include('gem "sentry-ruby"')
    expect(gemfile).to include('gem "sentry-rails"')
  end

  it "configures Sentry from environment variables" do
    expect(initializer).to include('config.dsn = ENV["SENTRY_DSN"]')
    expect(initializer).to include('ENV.fetch("SENTRY_ENVIRONMENT", Rails.env)')
    expect(initializer).to include('ENV["SENTRY_RELEASE"]')
    expect(initializer).to include('ENV.fetch("SENTRY_TRACES_SAMPLE_RATE", "0.1")')
    expect(initializer).to include('ENV.fetch("SENTRY_ENABLE_LOGS", "true")')
    expect(initializer).to include('ENV.fetch("SENTRY_SEND_DEFAULT_PII", "false")')
  end

  it "documents the GlitchTip instance hostname" do
    expect(initializer).to include("glitchtip.batb.love")
  end

  it "enables GlitchTip structured logs and sentry logger breadcrumbs" do
    expect(initializer).to include("config.enable_logs")
    expect(initializer).to include(":sentry_logger")
  end

  it "broadcasts the production rails logger to sentry" do
    expect(initializer).to include("Rails.env.production?")
    expect(initializer).to include("Rails.logger.broadcast_to(Sentry.logger)")
  end

  it "uses app-specific structured logging subscribers for requests and sql" do
    expect(initializer).to include('require "monitoring"')
    expect(initializer).to include("config.rails.structured_logging.subscribers")
    expect(initializer).to include("Monitoring::LogSubscribers::ActionControllerSubscriber")
    expect(initializer).to include("Monitoring::LogSubscribers::ActiveRecordSubscriber")
  end

  it "defines a top-level Monitoring entrypoint that loads its subcomponents" do
    monitoring_namespace = root.join("lib/monitoring.rb")

    expect(monitoring_namespace).to exist
    expect(monitoring_namespace.read).to include("module Monitoring")
    expect(monitoring_namespace.read).to include('require "monitoring/request_context"')
    expect(monitoring_namespace.read).to include('require "monitoring/reporter"')
    expect(monitoring_namespace.read).to include('require "monitoring/log_subscribers/action_controller_subscriber"')
    expect(monitoring_namespace.read).to include('require "monitoring/log_subscribers/active_record_subscriber"')
  end
end
