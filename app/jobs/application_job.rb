class ApplicationJob < ActiveJob::Base
  # Use GoodJob for background processing
  queue_adapter = :good_job

  # Automatically retry jobs that encountered a deadlock
  retry_on ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 3

  # Retry network-related errors for external API calls
  # retry_on Net::HTTPError, wait: :exponentially_longer, attempts: 5

  # Most jobs are safe to ignore if the underlying records are no longer available
  discard_on ActiveJob::DeserializationError

  # Log job execution
  before_perform do |job|
    Rails.logger.info "Starting job #{job.class.name} with arguments: #{job.arguments}"
  end

  after_perform do |job|
    Rails.logger.info "Completed job #{job.class.name}"
  end
end
