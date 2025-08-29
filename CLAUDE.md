# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Casmitter is a Ruby on Rails 8.0 podcast management application using modern Rails conventions with Hotwire for interactivity, TailwindCSS for styling, and SQLite/PostgreSQL for data storage.

## Development Commands

```bash
# Setup and Development
bin/setup                     # Initial project setup (installs deps, prepares DB)
bin/dev                       # Start development server with Tailwind CSS watching
bin/rails server              # Start Rails server only
bin/rails console             # Rails console

# Testing
bin/rails test                # Run all tests
bin/rails test test/models    # Run model tests
bin/rails test test/controllers # Run controller tests
bin/rails test:system         # Run system tests with Capybara
bin/rails test TEST=test/models/episode_test.rb # Run single test file

# Code Quality
bin/rubocop                   # Ruby linting (Rails Omakase conventions)
bin/rubocop -a                # Auto-fix linting issues
bin/brakeman                  # Security vulnerability scanning
bin/importmap audit           # Check JavaScript dependencies for vulnerabilities

# Database
bin/rails db:create           # Create database
bin/rails db:migrate          # Run pending migrations
bin/rails db:seed             # Load seed data
bin/rails db:reset            # Drop, create, migrate, and seed

# Asset Management
bin/rails assets:precompile   # Compile assets for production
bin/rails tailwindcss:build   # Build Tailwind CSS
bin/rails tailwindcss:watch   # Watch and rebuild CSS on changes

# Deployment
bin/kamal deploy              # Deploy to production using Kamal
```

## Architecture and Key Components

### Application Structure
- **Rails 8.0.1** with Ruby 3.3.6
- **Frontend**: Hotwire (Turbo + Stimulus), TailwindCSS 4.0, server-rendered HTML
- **Database**: SQLite (development), PostgreSQL (production)
- **File Storage**: AWS S3 with presigned URLs for secure uploads
- **Background Jobs**: SolidQueue (replaces Sidekiq)
- **Caching**: SolidCache (replaces Redis)
- **WebSockets**: SolidCable (replaces Redis for ActionCable)

### Domain Model
- `Episode`: Core content model with title, description, audio_url, duration, published status
- `Attendee` (STI): Base class for `Host` and `Guest` with name and bio
- `Attendance`: Join table linking episodes to attendees with their role
- `User`: Admin users with bcrypt authentication
- `Session`: Cookie-based session management

### Controller Architecture
1. **Public Controllers** (app/controllers/):
   - `EpisodesController`: Public episode listing and display
   - `AttendancesController`: View episode attendees
   - `SessionsController`: Admin login/logout

2. **Admin Namespace** (app/controllers/admin/):
   - `Admin::BaseController`: Base controller with authentication
   - `Admin::EpisodesController`: CRUD operations with pagination (Kaminari)
   - `Admin::AttendeesController`: Manage hosts and guests
   - All admin controllers inherit from `Admin::BaseController` for authentication

3. **API Controllers** (app/controllers/api/):
   - `Api::PresignedUrlsController`: Generate S3 presigned URLs for uploads (requires admin auth)

### Frontend Patterns
- **Hotwire-first approach**: Minimal JavaScript, server-rendered with Turbo enhancements
- **Stimulus Controllers**:
  - `file_upload_controller.js`: Drag-and-drop file uploads with progress tracking
  - `hello_controller.js`: Example controller
- **TailwindCSS 4.0**: Utility-first CSS with custom configuration
- **ViewComponents**: Not used, traditional Rails partials preferred

### File Upload System
- Direct uploads to S3 using presigned URLs
- Drag-and-drop interface with progress tracking
- File validation and error handling in Stimulus controller
- Admin authentication required for presigned URL generation

### Testing Strategy
- **Minitest** for unit and integration tests
- **Capybara** for system tests
- **Fixtures** for test data
- Tests located in `test/` directory following Rails conventions

### Deployment
- **Docker** containerization with multi-stage builds
- **Kamal** for deployment orchestration
- **GitHub Actions** CI/CD pipeline:
  - Automated testing on push
  - Security scanning with Brakeman
  - Code linting with Rubocop
  - Dependency auditing

## Key Conventions

### Rails Omakase Defaults
- Follow Rails 8.0 conventions and best practices
- Use Rails Omakase Rubocop rules for code style
- Prefer server-rendered HTML with Hotwire enhancements over SPAs
- Use built-in Rails features over external gems when possible

### Database and Models
- Use Rails migrations for schema changes
- Follow ActiveRecord conventions for associations
- Use STI (Single Table Inheritance) for related model types
- Validate data at the model level

### Authentication and Authorization
- Custom authentication using bcrypt (not Devise)
- Session-based authentication for admin area
- Require authentication for all admin actions via `Admin::BaseController`

### Frontend Development
- Write Stimulus controllers for JavaScript interactions
- Use Turbo Frames and Streams for partial page updates
- Keep JavaScript minimal and focused on enhancing server-rendered HTML
- Use TailwindCSS utilities for styling

### File Structure
- Controllers in `app/controllers/` with admin namespace in `admin/` subdirectory
- Models in `app/models/`
- Views in `app/views/` following controller structure
- JavaScript in `app/javascript/controllers/` (Stimulus)
- Stylesheets in `app/assets/stylesheets/`

## Important Notes

- The application uses Rails 8.0's new solid gems (SolidQueue, SolidCache, SolidCable) instead of Redis/Sidekiq
- RSS feed generation is built-in at `/episodes.rss` for podcast syndication
- The admin panel requires authentication for all actions
- File uploads go directly to S3 without touching the Rails server
- Pagination is implemented using Kaminari gem for admin episode listing
- The project uses SQLite in development for simplicity but PostgreSQL in production