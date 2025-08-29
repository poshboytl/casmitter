# Staging Environment Deployment Guide

This document describes how to deploy the Casmitter application to a staging server using Docker Compose.

## System Requirements

- Docker 20.10+
- Docker Compose 2.0+
- At least 2GB available memory
- At least 10GB available disk space
- Domain name and DNS configuration (for SSL certificates)

## File Structure

```
.
├── docker-compose.staging.yml    # Docker Compose configuration file
├── staging.env                   # Environment variables configuration
├── deploy-staging.sh            # Deployment script
├── nginx/                       # Nginx configuration directory
│   ├── nginx.conf              # Nginx main configuration
│   ├── ssl.conf                # SSL configuration
│   └── conf.d/                 # Site configuration
│       └── default.conf        # Default site configuration
└── STAGING_DEPLOYMENT.md       # This document
```

## Quick Start

### 1. Configure Environment Variables

For detailed environment variable configuration, please refer to the `ENV_CONFIG.md` file.

Copy and edit the environment variables file:

```bash
cp staging.env staging.env.local
nano staging.env.local
```

**Important Configuration Items:**

- `POSTGRES_PASSWORD`: PostgreSQL database password
- `REDIS_PASSWORD`: Redis password
- `SECRET_KEY_BASE`: Rails secret key (for session encryption)
- `CERTBOT_EMAIL`: Email address for SSL certificates
- `DOMAIN_NAME`: Your domain name (e.g., staging.yourdomain.com)
- `S3_ACCESS_KEY_ID`: S3 access key
- `S3_BUCKET`: S3 bucket name
- `S3_REGION`: S3 region
- `S3_ENDPOINT`: S3 endpoint URL
- `S3_SECRET_ACCESS_KEY`: S3 secret access key

#### Generate SECRET_KEY_BASE

If you need to generate a new `SECRET_KEY_BASE`, you can use the deployment script:

```bash
./deploy-staging.sh generate-secret
```

Or generate manually:

```bash
ruby -e "require 'securerandom'; puts SecureRandom.hex(64)"
```

### 2. Deploy Application

```bash
# Give execution permission to deployment script
chmod +x deploy-staging.sh

# Start all services
./deploy-staging.sh start
```

### 3. Setup SSL Certificates

```bash
# Setup SSL certificates (requires domain to point to server)
./deploy-staging.sh ssl
```

## Service Description

### PostgreSQL Database
- **Port**: 5432
- **Database**: casmitter_staging
- **User**: casmitter
- **Data Persistence**: Via Docker volume

### Redis Cache
- **Port**: 6379
- **Password Protection**: Enabled
- **Data Persistence**: Via Docker volume

### Rails Application
- **Port**: 3000 (internal)
- **Environment**: staging
- **Health Check**: Automatic monitoring

### Nginx Reverse Proxy
- **Port**: 80 (HTTP), 443 (HTTPS)
- **SSL**: Automatic Let's Encrypt certificates
- **Static Files**: Cache optimization
- **Security Headers**: Automatically added

## Deployment Script Commands

```bash
./deploy-staging.sh start      # Start all services
./deploy-staging.sh stop       # Stop all services
./deploy-staging.sh restart    # Restart all services
./deploy-staging.sh logs       # View logs
./deploy-staging.sh status     # View service status
./deploy-staging.sh ssl        # Setup SSL certificates
./deploy-staging.sh setup-db   # Setup database
```

## Monitoring and Maintenance

### View Service Status

```bash
docker-compose -f docker-compose.staging.yml ps
```

### View Logs

```bash
# All service logs
docker-compose -f docker-compose.staging.yml logs

# Specific service logs
docker-compose -f docker-compose.staging.yml logs app
docker-compose -f docker-compose.staging.yml logs nginx
```

### Database Backup

```bash
# Backup database
docker-compose -f docker-compose.staging.yml exec postgres pg_dump -U casmitter casmitter_staging > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore database
docker-compose -f docker-compose.staging.yml exec -T postgres psql -U casmitter casmitter_staging < backup_file.sql
```

## Troubleshooting

### Common Issues

1. **SSL Certificate Application Failed**
   - Ensure domain name correctly points to server
   - Check if firewall allows ports 80 and 443
   - Verify email address format

2. **Database Connection Failed**
   - Check PostgreSQL service status
   - Verify database password configuration
   - View database logs

3. **Application Cannot Be Accessed**
   - Check all service status
   - View application logs
   - Verify port configuration

### Log Locations

- **Application Logs**: `./log/`
- **Nginx Logs**: `./nginx/logs/`
- **Docker Logs**: `docker-compose logs`

## Security Recommendations

1. **Password Security**
   - Use strong passwords
   - Change passwords regularly
   - Don't hardcode passwords in code

2. **Network Security**
   - Only open necessary ports
   - Use firewall rules
   - Update dependencies regularly

3. **SSL Configuration**
   - Enable HSTS (production environment)
   - Use strong cipher suites
   - Update certificates regularly

## Performance Optimization

1. **Database Optimization**
   - Adjust connection pool size
   - Optimize queries
   - Regular maintenance

2. **Caching Strategy**
   - Redis persistence
   - Application-level caching
   - Static file caching

3. **Nginx Optimization**
   - Gzip compression
   - Static file caching
   - Connection pool configuration

## Update Deployment

```bash
# Stop services
./deploy-staging.sh stop

# Pull latest code
git pull origin main

# Rebuild and start
docker-compose -f docker-compose.staging.yml build
./deploy-staging.sh start
```

## Contact Support

If you encounter issues, please check:
1. Service status and logs
2. Environment variable configuration
3. Network and port configuration
4. System resource usage

---

**Note**: This is staging environment configuration. For production environment, please use the corresponding production configuration files.
