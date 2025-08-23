source "https://rubygems.org"

ruby "3.3.6"

# Core Rails Framework
gem "rails", "~> 8.0.1"
gem "propshaft"
gem "bootsnap", require: false

# Web Server & Performance
gem "puma", ">= 5.0"
gem "thruster", require: false

# Frontend & Assets
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-ruby", "~> 4.0"
gem "tailwindcss-rails", "~> 4.0"

# Data & Storage
gem "pg", group: :production
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Authentication & Security
gem "bcrypt", "~> 3.1.7"

# File Upload & Processing
# gem "shrine", "~> 3.6"
gem "aws-sdk-s3", "~> 1.14"
# gem "image_processing", "~> 1.2"

# API & Data Format
gem "jbuilder"

# Text Processing
gem 'redcarpet'

# Pagination
gem 'kaminari'

# Deployment & DevOps
gem "kamal", require: false

# Platform Specific
gem "tzinfo-data", platforms: %i[ windows jruby ]

group :development, :test do
  # Debugging & Development Tools
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "web-console", group: :development

  # Security & Code Quality
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false

  # Database
  gem "sqlite3", ">= 2.1"
end

group :test do
  # Testing
  gem "capybara"
  gem "selenium-webdriver"
end
