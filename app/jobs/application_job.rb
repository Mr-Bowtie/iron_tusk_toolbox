class ApplicationJob < ActiveJob::Base
  # Use GoodJob for background processing
  queue_adapter = :good_job

  # Automatically retry jobs that encountered a deadlock
  retry_on ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 3

  # Retry network-related errors for external API calls
  # retry_on Net::HTTPError, wait: :exponentially_longer, attempts: 5

  # Most jobs are safe to ignore if the underlying records are no longer available
  discard_on ActiveJob::DeserializationError

  around_perform do |job, block|
    Sentry.with_scope do |scope|
      scope.set_tags(job: job.class.name, queue: job.queue_name)
      scope.set_context("job", {
        "job_id" => job.job_id,
        "arguments" => job.arguments
      })

      Monitoring::Reporter.log(
        :info,
        "Job started",
        job: job.class.name,
        job_id: job.job_id,
        queue: job.queue_name
      )

      block.call

      Monitoring::Reporter.log(
        :info,
        "Job completed",
        job: job.class.name,
        job_id: job.job_id,
        queue: job.queue_name
      )
    rescue StandardError => e
      Monitoring::Reporter.log(
        :error,
        "Job failed",
        job: job.class.name,
        job_id: job.job_id,
        queue: job.queue_name,
        error_class: e.class.name,
        error_message: e.message
      )
      raise
    end
  end
end
