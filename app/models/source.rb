class Source < ApplicationRecord
  validates :url, :source_type, :platform, presence: true
  validates :url, uniqueness: true
  validates :source_type, inclusion: { in: %w[video playlist channel] }
  validates :platform, inclusion: { in: %w[youtube] }
end
