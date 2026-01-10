class VideosController < ApplicationController
  def create
    case classifier.link_type
    when :video
      add_to_default_feed
    when :playlist
      # TODO create new feed and associate all videos with it
    when :channel
      # similar to playlist but for the channel
    else
      # TODO impliment something here for sure
    end
  end

  def add_to_default_feed
    @feed = find_or_create_feed
    @video = @feed.videos.create! video_params

    VideoMetadataFetcherJob.perform_later(@video.id)
    VideoDownloaderJob.perform_later(@video.id)

    render json: {
      id: @video.id,
      feed_id: @feed.id,
      url: @video.url,
    }, status: :created
  end

  def destroy
    @video = Video.find params[:id]
    @video.destroy

    render json: @video
  end

  private

  def find_or_create_feed
    if params[:feed_id]
      Feed.find params[:feed_id]
    else
      Feed.create!(name: 'Default')
    end
  end

  def url
    params.require(:url)
  end

  def video_params
    {
      url: url,
      platform: classifier.platform,
    }
  end

  def classifier
    @classifier ||= VideoClassifier.new(url: url)
  end
end
