class Video < ApplicationRecord
  validates :url, :platform, presence: true
  validates :platform, inclusion: { in: %w[youtube] }

  belongs_to :feed
  has_one :download, dependent: :destroy

  # Estimate MP3 file size based on duration
  # Assumes 128kbps bitrate (typical for YouTube audio)
  def estimated_file_size
    return 0 unless duration.present?

    # Parse duration string (e.g., "2:24" or "1:30:45") to seconds
    duration_in_seconds = parse_duration_to_seconds(duration)
    return 0 if duration_in_seconds.zero?

    # Convert duration from seconds to bytes
    # 128kbps = 16KB/s (128 / 8 = 16)
    duration_in_seconds * 16 * 1024
  end

  private

  def parse_duration_to_seconds(duration_str)
    parts = duration_str.split(':').map(&:to_i)
    case parts.length
    when 3  # H:MM:SS
      parts[0] * 3600 + parts[1] * 60 + parts[2]
    when 2  # M:SS
      parts[0] * 60 + parts[1]
    when 1  # SS
      parts[0]
    else
      0
    end
  end
end
