# frozen_string_literal: true

module Monitoring
  module Reporter
    module_function

    def capture_exception(exception, tags: {}, extra: {}, message: nil, level: :error)
      log(level, message || exception.message, exception_class: exception.class.name, **extra)
      return unless sentry_available?

      Sentry.with_scope do |scope|
        scope.set_tags(tags.compact_blank) if tags.present?

        monitoring_context = extra.deep_stringify_keys.compact_blank
        monitoring_context["message"] = message if message.present?
        scope.set_context("monitoring", monitoring_context) if monitoring_context.any?

        Sentry.capture_exception(exception)
      end
    end

    def log(level, message, **context)
      formatted_message = format_message(message, context)

      Rails.logger.public_send(level, formatted_message)
      return unless sentry_logger&.respond_to?(level)

      sentry_logger.public_send(level, formatted_message)
    end

    def sentry_available?
      defined?(Sentry) && sentry_logger.present?
    end

    def sentry_logger
      return unless defined?(Sentry) && Sentry.respond_to?(:logger)

      Sentry.logger
    end

    def format_message(message, context)
      normalized_context = context.deep_stringify_keys.compact_blank
      return message if normalized_context.empty?

      "#{message} #{normalized_context.map { |key, value| "#{key}=#{value}" }.join(' ')}"
    end
    private_class_method :format_message
  end
end
