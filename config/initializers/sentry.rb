# frozen_string_literal: true

# GlitchTip speaks the Sentry protocol. Create a project in
# https://glitchtip.batb.love, then set SENTRY_DSN to that project's DSN.
Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.environment = ENV.fetch("SENTRY_ENVIRONMENT", Rails.env)
  config.release = ENV["SENTRY_RELEASE"]

  config.breadcrumbs_logger = [ :active_support_logger, :http_logger, :sentry_logger ]
  config.traces_sample_rate = Float(ENV.fetch("SENTRY_TRACES_SAMPLE_RATE", "0.1"))
  config.enable_logs = ActiveModel::Type::Boolean.new.cast(ENV.fetch("SENTRY_ENABLE_LOGS", "true"))
  config.send_default_pii = ActiveModel::Type::Boolean.new.cast(ENV.fetch("SENTRY_SEND_DEFAULT_PII", "false"))
end
