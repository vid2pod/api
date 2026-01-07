class VideosController < ApplicationController
  def create
    @feed = Feed.find params[:feed_id]
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
