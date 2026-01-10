class Provider::YouTube::Downloader < Provider::YouTube::Base
  class << self
    def download(url)
      temp_dir = Rails.root.join('tmp', 'downloads')
      FileUtils.mkdir_p(temp_dir)

      filename = "#{SecureRandom.uuid}.mp3"
      output_template = temp_dir.join(filename.gsub('.mp3', '.%(ext)s')).to_s

      # Create temp cookies file
      cookies_file = write_cookies_file

      command = build_command(url, output_template, cookies_file)

      # Debug logging
      Rails.logger.info("yt-dlp command: #{command.join(' ')}")

      stdout, stderr, status = Open3.capture3(*command)

      unless status.success?
        error_message = parse_error(stderr)
        cleanup_cookies_file(cookies_file)
        raise "yt-dlp download failed for #{url}: #{error_message}"
      end

      cleanup_cookies_file(cookies_file)
      temp_dir.join(filename)
    end

    private

    def build_command(url, output_template, cookies_file)
      command = [
        'yt-dlp',
        '--js-runtimes', 'node',
        '--remote-components', 'ejs:github',
        '--cookies', cookies_file.to_s,
        '--user-agent', user_agent,
        '--retries', '3',
        '--fragment-retries', '3',
        '--no-check-certificates',
        '-x',
        '--audio-format', 'mp3',
        '--audio-quality', '0',  # Best quality
        '-o', output_template
      ]

      # Add ffmpeg location if it exists (Heroku buildpack installs to /app/vendor/ffmpeg)
      ffmpeg_paths = [
        '/app/vendor/ffmpeg/bin',
        '/app/vendor/ffmpeg',
        ENV['FFMPEG_PATH']
      ].compact

      # Debug: Check which ffmpeg
      ffmpeg_which = `which ffmpeg 2>&1`.strip
      Rails.logger.info("which ffmpeg: #{ffmpeg_which}")
      Rails.logger.info("Checking ffmpeg paths: #{ffmpeg_paths.inspect}")

      ffmpeg_path = ffmpeg_paths.find { |path| Dir.exist?(path) }
      if ffmpeg_path
        Rails.logger.info("Found ffmpeg at: #{ffmpeg_path}")
        command += ['--ffmpeg-location', ffmpeg_path]
      else
        Rails.logger.warn("No ffmpeg path found. Tried: #{ffmpeg_paths.inspect}")
      end

      command << url
      command
    end
  end
end
