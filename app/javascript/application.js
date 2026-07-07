import * as Sentry from "@sentry/browser"
import { Application } from "@hotwired/stimulus"
import "@hotwired/turbo-rails"
import "./controllers"

const application = Application.start()

const sentryMeta = (name) => document.querySelector(`meta[name="${name}"]`)?.content
const sentryDsn = sentryMeta("sentry-dsn")

if (sentryDsn) {
  Sentry.init({
    dsn: sentryDsn,
    environment: sentryMeta("sentry-environment"),
    release: sentryMeta("sentry-release"),
    tracesSampleRate: Number(sentryMeta("sentry-traces-sample-rate") || "0.1"),
    autoSessionTracking: false,
    enableLogs: sentryMeta("sentry-enable-logs") !== "false"
  })
}

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

const originalHandleError = application.handleError.bind(application)
application.handleError = (error, message, detail) => {
  if (sentryDsn) {
    Sentry.withScope((scope) => {
      scope.setContext("stimulus", {
        message,
        controller: detail?.identifier,
        event: detail?.event?.type
      })
      Sentry.captureException(error)
    })
  }

  originalHandleError(error, message, detail)
}

export { application }
