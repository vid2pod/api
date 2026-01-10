class Provider::YouTube::UrlExtractor < Provider::YouTube::Base
  class << self
    def extract(url)
      # Create temp cookies file
      cookies_file = write_cookies_file

      command = build_command(url, cookies_file)

      stdout, stderr, status = Open3.capture3(*command)

      unless status.success?
        error_message = parse_error(stderr)
        cleanup_cookies_file(cookies_file)
        raise "yt-dlp URL extraction failed for #{url}: #{error_message}"
      end

      cleanup_cookies_file(cookies_file)

      # Return the extracted direct URL
      stdout.strip
    end

    private

    def build_command(url, cookies_file)
      [
        'yt-dlp',
        '-g',  # Get direct URL
        '--format', 'bestaudio',
        '--js-runtimes', 'node',
        '--remote-components', 'ejs:github',
        '--cookies', cookies_file.to_s,
        '--user-agent', user_agent,
        '--retries', '3',
        '--no-check-certificates',
        url
      ]
    end
  end
end
