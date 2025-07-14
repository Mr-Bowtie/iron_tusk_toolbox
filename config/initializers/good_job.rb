Rails.application.configure do
  config.active_job.queue_adapter = :good_job
  
  config.good_job.preserve_job_records

  # Configure GoodJob to use PostgreSQL
  config.good_job.execution_mode = :async
  config.good_job.queues = '*'
  config.good_job.max_threads = 5
  config.good_job.poll_interval = 30 # seconds
  
  # Enable the GoodJob dashboard in development
  config.good_job.enable_cron = true
  
  # Configure scheduled jobs (cron-style)
  config.good_job.cron = {
    # Daily Scryfall sync at 2 AM
    scryfall_daily_sync: {
      cron: "0 2 * * *", # Every day at 2:00 AM
      class: "ScryfallDataSyncJob"
    }
  }
  
  # In production, you might want to be more conservative
  if Rails.env.production?
    config.good_job.max_threads = 3
    config.good_job.poll_interval = 60
  end
end
