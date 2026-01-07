class VideosController < ApplicationController
  def create
    @feed = find_or_create_feed
    @video = @feed.videos.create! video_params

    VideoMetadataFetcherJob.perform_now(@video.id)
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

  def find_or_create_default_feed
    Feed.find_or_create_by!(name: 'Default')
  end

  def url
    params.require(:url)
  end

  def video_params
    {
      url: url,
      platform: 'youtube',
    }
  end
end
