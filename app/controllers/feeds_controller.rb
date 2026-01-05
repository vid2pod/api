class FeedsController < ApplicationController
  # Include modules needed for template rendering
  include ActionController::Rendering
  include ActionView::Rendering
  include ActionView::Layouts
  include Rails.application.routes.url_helpers

  def show
    @feed = Feed.find params[:id]

    render :show
  end

  private

  def default_url_options
    if ENV['APP_HOST'].present?
      { host: ENV['APP_HOST'], protocol: 'https', port: nil }
    else
      super
    end
  end
end
