# Redis configuration
# Use environment variables directly to avoid ERB template issues during Docker build
$redis = Redis.new(
  url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
  password: ENV.fetch("REDIS_PASSWORD", ""),
  ssl: ENV.fetch("REDIS_SSL", "false") == "true",
  timeout: ENV.fetch("REDIS_TIMEOUT", 1).to_i,
  reconnect_attempts: ENV.fetch("REDIS_RECONNECT_ATTEMPTS", 1).to_i
)

# Redis namespace for different environments
$redis_ns = Redis::Namespace.new(Rails.env, redis: $redis)

# Health check
begin
  $redis.ping
  Rails.logger.info "Redis connected successfully"
rescue Redis::BaseConnectionError => e
  Rails.logger.error "Redis connection failed: #{e.message}"
  raise e
end
