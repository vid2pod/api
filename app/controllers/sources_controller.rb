class SourcesController < ApplicationController
  def create
    @feed = find_or_create_default_feed
    @source = @feed.sources.create source_params
  end

  private

  def find_or_create_default_feed
    @feed = Feed.find_or_create_by name: 'Default'
  end

  def source_params
    params.require(:url).merge(
      source_type: 'video',
      platform: 'youtube',
    )
  end
end
