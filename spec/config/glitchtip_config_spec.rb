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
end
