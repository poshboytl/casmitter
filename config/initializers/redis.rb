# Redis configuration
# Use lazy initialization to avoid connection during Docker build

# Define Redis configuration method
def redis_config
  @redis_config ||= {
    url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
    password: ENV.fetch("REDIS_PASSWORD", ""),
    ssl: ENV.fetch("REDIS_SSL", "false") == "true",
    timeout: ENV.fetch("REDIS_TIMEOUT", 1).to_i,
    reconnect_attempts: ENV.fetch("REDIS_RECONNECT_ATTEMPTS", 1).to_i
  }
end

# Lazy initialization of Redis connection
def redis
  @redis ||= begin
    Redis.new(redis_config).tap do |conn|
      # Test connection only when actually needed
      conn.ping
      Rails.logger.info "Redis connected successfully" if defined?(Rails)
    end
  rescue Redis::BaseConnectionError => e
    Rails.logger.error "Redis connection failed: #{e.message}" if defined?(Rails)
    raise e
  end
end

# Redis namespace for different environments
def redis_ns
  @redis_ns ||= Redis::Namespace.new(Rails.env, redis: redis)
end

# Make methods available globally
$redis = method(:redis)
$redis_ns = method(:redis_ns)
