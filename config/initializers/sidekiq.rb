# Sidekiq configuration
Sidekiq.configure_server do |config|
  config.redis = {
    url: ENV.fetch("REDIS_URL", "redis://localhost:6379/2"),
    password: ENV.fetch("REDIS_PASSWORD", ""),
    ssl: ENV.fetch("REDIS_SSL", "false") == "true",
    namespace: "#{Rails.env}_queue"
  }
  
  # Configure concurrency
  config.concurrency = ENV.fetch("SIDEKIQ_CONCURRENCY", 5).to_i
  
  # Configure queues
  config.queues = %w[default mailers active_storage high low]
  
  # Configure logging
  config.logger.level = Logger::INFO
  
  # Configure error handling
  config.error_handlers << ->(ex, context) do
    Rails.logger.error "Sidekiq error: #{ex.message}"
    Rails.logger.error "Context: #{context}"
  end
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: ENV.fetch("REDIS_URL", "redis://localhost:6379/2"),
    password: ENV.fetch("REDIS_PASSWORD", ""),
    ssl: ENV.fetch("REDIS_SSL", "false") == "true",
    namespace: "#{Rails.env}_queue"
  }
end
