# Casmitter

> **Cast + Transmitter** - A modern podcast management and distribution platform

[![Ruby](https://img.shields.io/badge/Ruby-3.3.6-red.svg)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-8.0.1-red.svg)](https://rubyonrails.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 📖 Overview

Casmitter is a comprehensive podcast management platform built with Ruby on Rails 8. It provides tools for podcast creators to upload, manage, and distribute their content with ease. The platform features a modern web interface, robust file storage with S3 integration, and scalable architecture.

## ✨ Features

- 🎙️ **Podcast Management**: Upload, organize, and manage podcast episodes
- 📁 **File Storage**: Secure file storage with DigitalOcean Spaces (S3-compatible)
- 🌐 **Modern UI**: Responsive design built with Tailwind CSS
- 🚀 **Performance**: Optimized with Rails 8 and modern web technologies
- 🔒 **Security**: Secure authentication and file access controls
- 📱 **Responsive**: Mobile-friendly interface for all devices

## 🛠️ Tech Stack

- **Backend**: Ruby on Rails 8.0.1
- **Database**: PostgreSQL (production), SQLite3 (development)
- **Frontend**: Tailwind CSS, Stimulus, Turbo
- **Storage**: AWS S3 SDK with DigitalOcean Spaces
- **Authentication**: bcrypt
- **Deployment**: Kamal
- **Environment**: dotenv-rails for configuration management

## 🚀 Quick Start

### Prerequisites

- Ruby 3.3.6
- Rails 8.0.1
- PostgreSQL (for production)
- Node.js (for Tailwind CSS)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd casmitter
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env file with your actual configuration
   ```

4. **Set up database**
   ```bash
   rails db:create
   rails db:migrate
   ```

5. **Start the server**
   ```bash
   rails server
   ```

6. **Visit the application**
   Open [http://localhost:3000](http://localhost:3000) in your browser

## ⚙️ Configuration

### Environment Variables

Create a `.env` file in the root directory with the following variables:

```bash
# S3 Configuration
S3_ACCESS_KEY_ID=your_access_key_id
S3_BUCKET=your_bucket_name
S3_REGION=your_region
S3_ENDPOINT=your_endpoint_url
S3_SECRET_ACCESS_KEY=your_secret_access_key

# Rails Secret Key Base
SECRET_KEY_BASE=your_secret_key_base
```

### S3/DigitalOcean Spaces Setup

1. Create a DigitalOcean Spaces account
2. Create a new Space for your podcasts
3. Generate API keys with appropriate permissions
4. Update your `.env` file with the credentials

## 🗄️ Database

### Development
- Uses SQLite3 for simplicity
- Database file: `db/development.sqlite3`

### Production
- Uses PostgreSQL for reliability and performance
- Configure via `DATABASE_URL` environment variable

## 📁 Project Structure

```
casmitter/
├── app/
│   ├── controllers/     # Application controllers
│   ├── models/         # Data models
│   ├── services/       # Business logic services
│   ├── views/          # View templates
│   └── assets/         # CSS, JavaScript, images
├── config/             # Configuration files
├── db/                 # Database migrations and seeds
├── lib/                # Custom libraries
├── public/             # Static files
├── test/               # Test files
└── vendor/             # Third-party dependencies
```

## 🧪 Testing

Run the test suite:

```bash
# Run all tests
rails test

# Run specific test file
rails test test/models/user_test.rb

# Run tests with coverage
COVERAGE=true rails test
```

## 🚀 Deployment

### Using Kamal

This project is configured for deployment with Kamal:

```bash
# Deploy to production
kamal deploy

# Deploy to staging
kamal deploy --config config/deploy.staging.yml
```

### Environment Setup

Ensure your production environment has all required environment variables set:

```bash
# Set environment variables on your server
export S3_ACCESS_KEY_ID="your_key"
export S3_BUCKET="your_bucket"
# ... other variables
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow Ruby style guidelines (RuboCop is configured)
- Write tests for new features
- Update documentation as needed
- Ensure all tests pass before submitting PR

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Ruby on Rails](https://rubyonrails.org/)
- Styled with [Tailwind CSS](https://tailwindcss.com/)
- Deployed with [Kamal](https://kamal-deploy.org/)

## 📞 Support

If you have any questions or need help:

- Create an issue in the repository
- Check the documentation
- Review the configuration files

---

**Made with ❤️ using Ruby on Rails**
