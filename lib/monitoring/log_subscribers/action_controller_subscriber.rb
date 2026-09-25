# frozen_string_literal: true

require "sentry/rails/log_subscriber"
require "sentry/rails/log_subscribers/parameter_filter"

module Monitoring
  module LogSubscribers
    class ActionControllerSubscriber < Sentry::Rails::LogSubscriber
      include Sentry::Rails::LogSubscribers::ParameterFilter

      def process_action(event)
        return unless Sentry.initialized?

        payload = event.payload
        controller = payload[:controller]
        action = payload[:action]
        method = payload[:method]
        path = payload[:path]
        status = payload[:status]

        attributes = {
          controller: controller,
          action: action,
          method: method,
          path: path,
          format: payload[:format],
          status: status,
          request_id: payload[:request_id],
          duration_ms: duration_ms(event)
        }.compact

        attributes[:view_runtime_ms] = payload[:view_runtime].round(2) if payload[:view_runtime]
        attributes[:db_runtime_ms] = payload[:db_runtime].round(2) if payload[:db_runtime]

        if Sentry.configuration.send_default_pii && payload[:params]
          filtered_params = filter_sensitive_params(payload[:params])
          attributes[:params] = filtered_params unless filtered_params.empty?
        end

        Monitoring::RequestContext.request_id = payload[:request_id]
        Monitoring::RequestContext.controller = controller
        Monitoring::RequestContext.action = action
        Monitoring::RequestContext.method = method
        Monitoring::RequestContext.path = path
        Monitoring::RequestContext.format = payload[:format]&.to_s

        log_structured_event(
          message: [method, path, "#{controller}##{action}"].compact.join(" "),
          level: level_for(status, payload[:exception]),
          attributes: attributes
        )
      end

      private

      def level_for(status, exception)
        return :error if exception.present? && status.to_i >= 500
        return :error if status.to_i >= 500
        return :warn if status.to_i >= 400

        :info
      end
    end
  end
end
