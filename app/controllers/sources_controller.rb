class SourcesController < ApplicationController
  def create
    @source = Source.create(
      url: url_param,
      source_type: 'video',
      platform: 'youtube',
    )
  end
end
