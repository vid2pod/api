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

      # Heroku buildpack adds ffmpeg to PATH, so --ffmpeg-location shouldn't be needed
      # But if we need to specify it explicitly, it's at /app/vendor/ffmpeg
      if Dir.exist?('/app/vendor/ffmpeg')
        command += ['--ffmpeg-location', '/app/vendor/ffmpeg']
      end

      command << url
      command
    end
  end
end
