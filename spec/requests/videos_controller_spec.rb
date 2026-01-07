require 'rails_helper'

RSpec.describe 'VideosController', type: :request do

  describe '.create' do
    let!(:feed) { Feed.create!(name: 'Test Feed') }
    let(:url) { 'https://www.youtube.com/watch?v=dQw4w9WgXcQ' }
    let(:valid_params) do
      { url: url }
    end

    context 'when creating a video with valid parameters' do
      it 'creates a new video associated with the feed' do
        expect {
          post feed_videos_path(feed), params: valid_params
        }.to change(Video, :count).by(1)
      end

      it 'creates the video with the correct attributes' do
        post feed_videos_path(feed), params: valid_params

        video = Video.last
        expect(video.url).to eq(url)
        expect(video.platform).to eq('youtube')
      end

      it 'associates the video with the feed' do
        post feed_videos_path(feed), params: valid_params

        video = Video.last
        expect(video.feed).to be_present
        expect(video.feed.id).to eq(feed.id)
      end

      it 'returns a 201 created status' do
        post feed_videos_path(feed), params: valid_params

        expect(response).to have_http_status(:created)
      end

      it 'returns JSON with the video id, feed_id, and url' do
        post feed_videos_path(feed), params: valid_params

        video = Video.last
        json_response = JSON.parse(response.body)

        expect(json_response['id']).to eq(video.id)
        expect(json_response['feed_id']).to eq(video.feed.id)
        expect(json_response['url']).to eq(url)
      end

      it 'does not create a new feed' do
        expect {
          post feed_videos_path(feed), params: valid_params
        }.not_to change(Feed, :count)
      end
    end
  end
end
