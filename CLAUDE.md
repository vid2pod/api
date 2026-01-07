# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

vid2pod is a Rails 8 API application that converts YouTube videos into podcast RSS feeds. It downloads video audio as MP3 files and generates Apple Podcast-compatible RSS feeds.

## Development Commands

### Setup
```bash
bin/setup                    # Initial setup: installs dependencies, creates database
bin/rails db:migrate         # Run pending migrations
```

### Running the Application
```bash
bin/dev                      # Start Rails server (alias for bin/rails server)
bin/rails server             # Alternative way to start server
```

### Testing
```bash
bundle exec rspec                           # Run all tests
bundle exec rspec spec/requests/            # Run request specs
bundle exec rspec spec/jobs/                # Run job specs
bundle exec rspec spec/path/to/file_spec.rb # Run specific test file
```

### Database
```bash
bin/rails db:create          # Create database
bin/rails db:reset           # Drop, create, and migrate database
bin/rails console            # Open Rails console
```

## Architecture

### Data Model

**Feed → Videos → Download**

- `Feed`: Represents a podcast feed (has many videos)
  - Fields: `name`, `url`
  - Generates RSS XML feed at `/feeds/:id.xml`

- `Video`: Individual video entry in a feed (belongs to feed)
  - Fields: `url`, `platform` (currently only 'youtube'), `title`, `description`, `external_id`, `duration`, `thumbnail`, `published_at`
  - Has one associated download

- `Download`: Tracks download status and stores audio file (belongs to video)
  - Fields: `status` ('pending', 'downloading', 'completed', 'failed')
  - Uses ActiveStorage to store MP3 files

### Video Processing Flow

When a video is created (POST `/videos`):
1. `VideoMetadataFetcherJob` - Fetches metadata (title, description, duration, thumbnail) from YouTube
2. `VideoDownloaderJob` - Downloads audio as MP3 and attaches to Download record via ActiveStorage

Both jobs run asynchronously via ActiveJob (default: async adapter in development).

### Provider Pattern

Video platform interactions are abstracted through a provider pattern in `app/services/provider/`:

- `Provider::YouTube::Metadata` - Uses yt-dlp to fetch video metadata
- `Provider::YouTube::Downloader` - Uses yt-dlp to download audio as MP3

This pattern allows for future expansion to other video platforms (Vimeo, etc.).

### External Dependency: yt-dlp

The application requires `yt-dlp` to be installed on the system:
```bash
brew install yt-dlp  # macOS
```

All YouTube interactions go through yt-dlp command-line tool via shell commands.

### Storage Configuration

- **Development**: Local disk storage (`storage/`)
- **Production**: AWS S3 (configured via ENV variables: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `AWS_BUCKET`)

File URLs are generated with different hosts:
- Development: `http://localhost:3000`
- Production: `https://downloads.vid2pod.com` (from Download model) and `ENV['APP_HOST']` (from FeedsController)

### RSS Feed Generation

RSS feeds are generated using Rails Builder templates in `app/views/feeds/show.xml.builder`:
- Compliant with Apple Podcasts RSS requirements
- Includes iTunes-specific tags (`itunes:duration`, `itunes:image`, etc.)
- Each video becomes a podcast episode with an audio enclosure
- Only includes videos with completed downloads

### API-Only Rails App

This is an API-only Rails application (`config.api_only = true`), but selectively includes view rendering capabilities in FeedsController to support XML/JSON RSS feed generation.

## Key Routes

```
POST   /videos      # Create video (triggers metadata fetch + download jobs)
DELETE /videos/:id  # Delete video and associated download
GET    /feeds/:id   # Show feed (supports .xml and .json formats)
```

## Testing Strategy

- Request specs in `spec/requests/` test controller endpoints
- Job specs in `spec/jobs/` test background jobs
- Uses RSpec with FactoryBot for test data
- Test configuration in `spec/rails_helper.rb` and `spec/spec_helper.rb`

## Environment Configuration

Production environment expects:
- PostgreSQL database (config in `config/database.yml`)
- AWS S3 credentials for file storage
- `APP_HOST` environment variable for RSS feed URLs
- SSL enforced (`config.force_ssl = true`)
