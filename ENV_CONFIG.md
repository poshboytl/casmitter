# Environment Variables Configuration Guide

This document explains the environment variables required for the Casmitter project.

## Basic Configuration

### Rails Environment
```bash
# Rails Environment
RAILS_ENV=development          # or staging, production
SECRET_KEY_BASE=your_secret_key_base_here
```

### Database Configuration
```bash
# PostgreSQL Database
DATABASE_URL=postgresql://username:password@localhost:5432/casmitter_development
# Or configure separately
POSTGRES_PASSWORD=your_password
POSTGRES_DB=casmitter_development
POSTGRES_USER=casmitter
```

### Redis Configuration
```bash
# Redis Cache
REDIS_URL=redis://localhost:6379/0
# Or configure separately
REDIS_PASSWORD=your_redis_password
```

## S3/Object Storage Configuration

```bash
# S3 or DigitalOcean Spaces Configuration
S3_ACCESS_KEY_ID=your_access_key_id
S3_BUCKET=your_bucket_name
S3_REGION=your_region
S3_ENDPOINT=your_endpoint_url
S3_SECRET_ACCESS_KEY=your_secret_access_key
```

## Application Performance Configuration

```bash
# Application Performance Settings
RAILS_MAX_THREADS=5
WEB_CONCURRENCY=2
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
```

## Staging/Production Environment Additional Configuration

```bash
# Domain and SSL
DOMAIN_NAME=your-domain.com
CERTBOT_EMAIL=your-email@example.com

# Security Passwords
POSTGRES_PASSWORD=your_secure_postgres_password
REDIS_PASSWORD=your_secure_redis_password
```

## Generate SECRET_KEY_BASE

If you need to generate a new `SECRET_KEY_BASE`, you can use the following commands:

```bash
# Run in Rails project
rails secret

# Or use Ruby
ruby -e "require 'securerandom'; puts SecureRandom.hex(64)"
```

## Environment Variables File Examples

### Development Environment (.env)
```bash
RAILS_ENV=development
SECRET_KEY_BASE=your_dev_secret_key
DATABASE_URL=postgresql://casmitter:password@localhost:5432/casmitter_development
REDIS_URL=redis://localhost:6379/0
S3_ACCESS_KEY_ID=your_dev_key
S3_BUCKET=your_dev_bucket
S3_REGION=your_region
S3_ENDPOINT=your_endpoint
S3_SECRET_ACCESS_KEY=your_dev_secret
```

### Staging Environment (staging.env)
```bash
RAILS_ENV=staging
SECRET_KEY_BASE=your_staging_secret_key
POSTGRES_PASSWORD=your_staging_password
REDIS_PASSWORD=your_staging_redis_password
DOMAIN_NAME=staging.yourdomain.com
CERTBOT_EMAIL=admin@yourdomain.com
S3_ACCESS_KEY_ID=your_staging_key
S3_BUCKET=your_staging_bucket
S3_REGION=your_region
S3_ENDPOINT=your_endpoint
S3_SECRET_ACCESS_KEY=your_staging_secret
```

## Important Notes

1. **Security**: Don't hardcode sensitive information in code
2. **Environment Isolation**: Use different configuration files for different environments
3. **Password Strength**: Use strong passwords, especially for database and Redis
4. **Backup**: Regularly backup environment variable configurations
5. **Permissions**: Ensure environment variable files have appropriate file permissions

## Troubleshooting

### Common Issues

1. **SECRET_KEY_BASE Error**
   - Ensure SECRET_KEY_BASE is set
   - Check if key length is sufficient (at least 64 characters)

2. **Database Connection Failed**
   - Check DATABASE_URL format
   - Verify database service is running
   - Check username and password

3. **Redis Connection Failed**
   - Check REDIS_URL format
   - Verify Redis service is running
   - Check password configuration

4. **S3 Upload Failed**
   - Verify S3 credentials
   - Check bucket permissions
   - Confirm region and endpoint configuration
