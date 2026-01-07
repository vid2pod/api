require 'rails_helper'

RSpec.describe 'VideosController', type: :request do

  describe '.create' do
    let(:url) { 'https://www.youtube.com/watch?v=dQw4w9WgXcQ' }
    let(:valid_params) do
      { url: url }
    end

    context 'when creating a video with valid parameters' do
      it 'creates a new video associated with the default feed' do
        expect {
          post videos_path, params: valid_params
        }.to change(Video, :count).by(1)
      end

      it 'creates the video with the correct attributes' do
        post videos_path, params: valid_params

        video = Video.last
        expect(video.url).to eq(url)
        expect(video.platform).to eq('youtube')
      end

      it 'associates the video with the default feed' do
        post videos_path, params: valid_params

        video = Video.last
        expect(video.feed).to be_present
        expect(video.feed.name).to eq("Feed for #{url}")
      end

      it 'returns a 201 created status' do
        post videos_path, params: valid_params

        expect(response).to have_http_status(:created)
      end

      it 'returns JSON with the video id, feed_id, and url' do
        post videos_path, params: valid_params

        video = Video.last
        json_response = JSON.parse(response.body)

        expect(json_response['id']).to eq(video.id)
        expect(json_response['feed_id']).to eq(video.feed.id)
        expect(json_response['url']).to eq(url)
      end

      context 'if the default feed already exists' do
        before { Feed.create name: 'Default' }

        it 'uses the existing default feed' do
          expect {
            post videos_path, params: valid_params
          }.not_to change(Feed, :count)
        end
      end

      context 'if the default feed does not already exist' do
        it 'creates the default feed' do
          expect {
            post videos_path, params: valid_params
          }.to change(Feed, :count).by(1)
        end
      end
    end
  end
end
