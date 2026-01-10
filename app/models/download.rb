class Download < ApplicationRecord
  include Rails.application.routes.url_helpers

  belongs_to :video
  has_one_attached :file

  validates :status, inclusion: { in: %w[pending downloading completed failed] }

  def file_url
    return nil unless file.attached?

    if Rails.env.production?
      # Use direct S3 URL via CloudFront
      # file.url generates direct S3 path, we replace S3 hostname with CloudFront domain
      s3_url = file.url
      s3_url.gsub(/https?:\/\/[^\/]+/, 'https://downloads.vid2pod.fm')
    else
      # Use localhost Rails routing for development
      rails_blob_url(file, host: 'localhost', protocol: 'http', port: 3000)
    end
  end
end
