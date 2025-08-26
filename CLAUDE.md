# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Casmitter is a Ruby on Rails 8.0 podcast application that serves as a platform for hosting and distributing podcast episodes. It uses a modern Rails stack with Turbo, Stimulus, and Tailwind CSS for styling.

## Core Architecture

### Models
- **Episode**: Central model representing podcast episodes with status (draft/published/hidden), metadata, and file information
- **Attendee**: Base model for people involved in episodes, with Single Table Inheritance (STI) pattern
- **Host**: Inherits from Attendee, represents podcast hosts
- **Guest**: Inherits from Attendee, represents podcast guests  
- **Attendance**: Join table connecting Episodes and Attendees with role information (host/guest)
- **User/Session**: Authentication models using bcrypt

### Key Features
- Episodes have file URIs pointing to audio files, with duration and file size tracking
- Markdown rendering for episode descriptions using Redcarpet
- RSS feed generation for podcast distribution
- Episode lookup by both slug and number
- Social links storage as JSON in attendees
- File size fetching from remote URLs via custom FileUtils module

### Database
- Development/Test: SQLite3 
- Production: PostgreSQL with separate databases for cache, queue, and cable
- Uses Solid Cache, Solid Queue, and Solid Cable for Rails infrastructure

## Common Commands

### Development
```bash
# Start the Rails server
bin/rails server

# Start with file watching for assets
bin/rails tailwindcss:watch

# Database operations
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
```

### Testing
```bash
# Run all tests (except system tests)
bin/rails test

# Run specific test file
bin/rails test test/models/episode_test.rb

# Run test with line number
bin/rails test test/models/episode_test.rb:27

# Run system tests
bin/rails test:system
```

### Linting & Code Quality
```bash
# Run RuboCop linter
bundle exec rubocop

# Auto-fix RuboCop issues (safe)
bundle exec rubocop -a

# Auto-fix all RuboCop issues (including unsafe)
bundle exec rubocop -A

# Run Brakeman security scanner
bundle exec brakeman
```

### Episode Management
```bash
# Publish episodes (custom rake tasks)
bin/rails publish:episode_2
bin/rails publish:episode_3
bin/rails publish:episode_4

# Delete episodes
bin/rails publish:delete_episode_2
bin/rails publish:delete_episode_3
bin/rails publish:delete_episode_4
```

### Asset Management
```bash
# Build Tailwind CSS
bin/rails tailwindcss:build

# Watch for Tailwind changes
bin/rails tailwindcss:watch

# Precompile all assets
bin/rails assets:precompile
```

## Development Workflow

When working on this codebase:

1. **Database Changes**: Always create migrations for schema changes and run them in development
2. **Episode Publishing**: Use the custom rake tasks in `lib/tasks/publish.rake` for episode management
3. **File Size Tracking**: The `FileUtils.get_remote_file_size` method fetches remote file sizes for episodes
4. **Markdown Content**: Episode descriptions are stored in `db/seeds/` as markdown files and rendered using Redcarpet
5. **Testing**: Run tests after changes, especially for models and controllers
6. **Linting**: Run RuboCop to maintain code style consistency

## Deployment

- Uses Kamal for deployment with Docker
- Configured for single-server deployment with PostgreSQL
- SSL enabled via Let's Encrypt
- Persistent storage for SQLite files in development
- Assets are fingerprinted and cached between deployments

## Key File Locations

- Models: `app/models/`
- Controllers: `app/controllers/`
- Views: `app/views/`
- Routes: `config/routes.rb`
- Database config: `config/database.yml`
- Deployment config: `config/deploy.yml`
- Custom utilities: `lib/`
- Episode content: `db/seeds/`
- Tests: `test/`