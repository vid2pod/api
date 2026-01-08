class Download < ApplicationRecord
  include Rails.application.routes.url_helpers

  belongs_to :video
  has_one_attached :file

  validates :status, inclusion: { in: %w[pending downloading completed failed] }

  def file_url
    return nil unless file.attached?

    rails_blob_url(file, **default_url_options)
  end

  private

  def default_url_options
    if Rails.env.production?
      { host: 'downloads.vid2pod.fm', protocol: 'https', port: nil }
    else
      { host: 'localhost', protocol: 'http', port: 3000 }
    end
  end
end
