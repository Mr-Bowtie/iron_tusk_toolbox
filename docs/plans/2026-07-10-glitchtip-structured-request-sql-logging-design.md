# GlitchTip Structured Request and SQL Logging Design

## Goal

Expand GlitchTip logging so request and database activity carry useful structured context instead of only generic event names.

## Approach

Use app-specific Sentry Rails log subscribers for `action_controller` and `active_record` events. The custom controller subscriber will emit request lifecycle logs with method, path, status, timing, request id, and safe parameter summaries. The custom Active Record subscriber will emit SQL logs with statement names, timing, cache state, database metadata, and current request context from a lightweight request-scoped store.

## Safety

The design keeps `SENTRY_SEND_DEFAULT_PII=false` as the default. Request parameters and SQL binds stay filtered unless explicitly allowed. Raw response bodies will not be logged.

## Validation

Add pure unit specs for the custom log subscribers and a static initializer spec to verify the custom subscribers are wired into Sentry structured logging.
