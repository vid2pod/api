class VideosController < ApplicationController
  def create
    @feed = find_or_create_default_feed
    @video = @feed.videos.create! video_params

    MetadataFetcherJob.perform_later(@video.id)
    VideoDownloaderJob.perform_later(@video.id)

    # return a 201
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
