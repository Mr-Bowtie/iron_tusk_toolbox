# frozen_string_literal: true

require "sentry/rails/log_subscriber"

module Monitoring
  module LogSubscribers
    class ActiveRecordSubscriber < Sentry::Rails::LogSubscriber
      EXCLUDED_NAMES = ["SCHEMA", "TRANSACTION"].freeze

      def sql(event)
        return unless Sentry.initialized?
        return if EXCLUDED_NAMES.include?(event.payload[:name])

        payload = event.payload
        statement_name = payload[:name]
        sql = payload[:sql]

        attributes = {
          statement_name: statement_name,
          sql: sql,
          cached: payload.fetch(:cached, false),
          duration_ms: duration_ms(event),
          request_id: Monitoring::RequestContext.request_id,
          controller: Monitoring::RequestContext.controller,
          action: Monitoring::RequestContext.action,
          method: Monitoring::RequestContext.method,
          path: Monitoring::RequestContext.path
        }.compact

        add_db_config(attributes, payload[:connection])

        log_structured_event(
          message: build_message(statement_name),
          level: :info,
          attributes: attributes
        )
      end

      private

      def build_message(statement_name)
        if statement_name.present? && statement_name != "SQL"
          "Database query: #{statement_name}"
        else
          "Database query"
        end
      end

      def add_db_config(attributes, connection)
        return unless connection&.respond_to?(:pool)

        db_config = if connection.pool.respond_to?(:db_config)
          connection.pool.db_config
        end

        config_hash =
          if db_config&.respond_to?(:configuration_hash)
            db_config.configuration_hash
          elsif db_config&.respond_to?(:config)
            db_config.config
          elsif connection.respond_to?(:config)
            connection.config
          end

        return unless config_hash

        attributes[:db_system] = config_hash[:adapter] if config_hash[:adapter]
        attributes[:db_name] = config_hash[:database] if config_hash[:database]
        attributes[:server_address] = config_hash[:host] if config_hash[:host]
        attributes[:server_port] = config_hash[:port] if config_hash[:port]
      end
    end
  end
end
