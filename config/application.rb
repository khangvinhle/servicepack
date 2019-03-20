class Application < Rails::Application
  # ...
  config.active_job.queue_adapter = :sidekiq
end