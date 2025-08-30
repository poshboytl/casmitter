# Redis configuration
redis_config = YAML.load_file(Rails.root.join('config', 'redis.yml'))[Rails.env]

$redis = Redis.new(
  url: redis_config['url'],
  password: redis_config['password'],
  ssl: redis_config['ssl'],
  timeout: redis_config['timeout'],
  reconnect_attempts: redis_config['reconnect_attempts']
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
