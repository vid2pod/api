class VideoMetadataFetcherJob < ApplicationJob
  queue_as :default

  def perform(video_id)
    video = Video.find video_id

    metadata = Provider::YouTube::Metadata.fetch(video.url)

    video.update!(
      title: metadata[:title],
      description: metadata[:description],
      external_id: metadata[:id],
      duration: metadata[:duration_string],
      thumbnail: metadata[:thumbnail],
      published_at: Time.at(metadata[:timestamp]),
    )
  end
end
