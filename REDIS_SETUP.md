# Redis + Sidekiq + Action Cable 配置说明

## 环境变量配置

在staging环境中，需要设置以下环境变量：

```bash
# Redis 配置
export REDIS_URL="redis://localhost:6379/2"
export REDIS_PASSWORD=""
export REDIS_SSL="false"

# Sidekiq 配置
export SIDEKIQ_CONCURRENCY="10"

# 数据库配置
export DATABASE_HOST="localhost"
export DATABASE_PORT="5432"
export DATABASE_NAME="casmitter_staging"
export DATABASE_USERNAME="casmitter"
export DATABASE_PASSWORD=""
```

## 安装依赖

```bash
bundle install
```

## 启动服务

### 1. 启动Redis服务器
```bash
redis-server
```

### 2. 启动Sidekiq
```bash
bundle exec sidekiq -C config/sidekiq.yml -e staging
```

### 3. 启动Rails应用
```bash
bundle exec rails server -e staging
```

## 配置说明

### Redis
- 使用数据库2作为staging环境
- 支持密码认证和SSL连接
- 自动重连和错误处理

### Sidekiq
- 并发数：10（可通过环境变量调整）
- 队列优先级：high > default > mailers > active_storage > low
- 自动错误处理和日志记录

### Action Cable
- 使用Redis作为适配器
- 支持多进程通信
- 自动频道前缀管理

## 健康检查

可以通过以下方式检查服务状态：

```bash
# 检查Redis连接
bundle exec rails console -e staging
> $redis.ping
# 应该返回 "PONG"

# 检查Sidekiq状态
bundle exec sidekiq -C config/sidekiq.yml -e staging -T
```

## 故障排除

1. **Redis连接失败**：检查Redis服务是否启动，端口是否正确
2. **Sidekiq启动失败**：检查Redis连接和配置文件
3. **Action Cable不工作**：检查Redis连接和频道配置
