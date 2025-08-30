# Database Initialization Scripts

This directory contains scripts that run when the PostgreSQL container starts for the first time.

## How it works

PostgreSQL automatically executes all `.sql` and `.sh` files in this directory when the container initializes a new database. The files are executed in alphabetical order.

## Current scripts

- `01-init-database.sql` - Basic database setup, extensions, and permissions

## Environment setup

Since `.env` files are gitignored for security, you need to create the `.env` file manually:

1. Copy `staging.env` to `.env`:
   ```bash
   cp staging.env .env
   ```

2. Or create `.env` manually with the required variables:
   ```bash
   # Database
   DB_PASSWORD=your_password_here
   DB_NAME=casmitter_staging
   DB_USER=casmitter
   
   # Redis
   REDIS_PASSWORD=your_redis_password_here
   
   # Rails
   RAILS_ENV=staging
   SECRET_KEY_BASE=your_secret_key_here
   
   # Add other required variables...
   ```

## Adding new scripts

To add new initialization scripts:

1. Create a new `.sql` or `.sh` file
2. Use a numbered prefix (e.g., `02-`, `03-`) to control execution order
3. Make sure the script is idempotent (can run multiple times safely)

## Troubleshooting

If you encounter issues:

1. Check that `.env` file exists and contains correct values
2. Verify that `init-scripts` directory is properly mounted in docker-compose
3. Check PostgreSQL container logs for initialization errors
