-- Database initialization script for Casmitter staging environment
-- This script runs when the PostgreSQL container starts for the first time

-- Create the database if it doesn't exist (PostgreSQL will create it automatically from env vars)
-- Set timezone
SET timezone = 'UTC';

-- Create extensions if needed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Grant necessary permissions
GRANT ALL PRIVILEGES ON DATABASE casmitter_staging TO casmitter;

-- Log initialization
\echo 'Database initialization completed successfully!'
