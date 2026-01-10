require 'rails_helper'

RSpec.describe "FeedsController", type: :request do
  describe ".show" do
    let(:feed) { Feed.create!(name: 'Test Podcast Feed') }
    let(:xml) { Nokogiri::XML(response.body) }

    before do
      get feed_path(feed, format: :xml)
    end

    it 'returns successful XML response' do
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('application/xml')
    end

    describe 'RSS structure' do
      it 'renders RSS 2.0 with correct namespaces' do
        rss_element = xml.at_xpath('/rss')
        expect(rss_element['version']).to eq('2.0')

        # Check namespaces are defined in the raw XML
        expect(response.body).to include('xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd"')
        expect(response.body).to include('xmlns:content="http://purl.org/rss/1.0/modules/content/"')
        expect(response.body).to include('xmlns:podcast="https://podcastindex.org/namespace/1.0"')
        expect(response.body).to include('xmlns:atom="http://www.w3.org/2005/Atom"')
        expect(response.body).to include('xmlns:googleplay="http://www.google.com/schemas/play-podcasts/1.0"')
      end
    end

    describe 'channel metadata' do
      it 'renders channel title' do
        expect(xml.at_xpath('//channel/title').text).to eq('vid2pod.fm video feed')
      end

      it 'renders channel link' do
        expect(xml.at_xpath('//channel/link').text).to include(feed.id)
        expect(xml.at_xpath('//channel/link').text).to include('.xml')
      end

      it 'renders channel description' do
        expect(xml.at_xpath('//channel/description').text).to eq('the videos that the user has added to their vid2pod.fm feed')
      end

      it 'renders atom self-reference link' do
        atom_link = xml.at_xpath('//channel/atom:link', 'atom' => 'http://www.w3.org/2005/Atom')
        expect(atom_link['href']).to include(feed.id)
        expect(atom_link['rel']).to eq('self')
        expect(atom_link['type']).to eq('application/rss+xml')
      end

      it 'renders iTunes metadata' do
        expect(xml.at_xpath('//channel/itunes:type', 'itunes' => 'http://www.itunes.com/dtds/podcast-1.0.dtd').text).to eq('episodic')
        expect(xml.at_xpath('//channel/itunes:author', 'itunes' => 'http://www.itunes.com/dtds/podcast-1.0.dtd').text).to eq('Test Podcast Feed')
        expect(xml.at_xpath('//channel/itunes:explicit', 'itunes' => 'http://www.itunes.com/dtds/podcast-1.0.dtd').text).to eq('false')
      end

      it 'renders language' do
        expect(xml.at_xpath('//channel/language').text).to eq('en-US')
      end

      it 'renders generator' do
        expect(xml.at_xpath('//channel/generator').text).to eq('vid2pod')
      end

      it 'renders lastBuildDate as feed updated_at' do
        expect(xml.at_xpath('//channel/lastBuildDate').text).to eq(feed.updated_at.rfc2822)
      end

      context 'when feed has videos with published_at' do
        before do
          feed.videos.create!(
            url: 'https://youtube.com/watch?v=abc',
            platform: 'youtube',
            published_at: 2.days.ago
          )
          get feed_path(feed, format: :xml)
        end

        it 'renders pubDate as most recent video published_at' do
          expect(xml.at_xpath('//channel/pubDate').text).to eq(feed.videos.maximum(:published_at).rfc2822)
        end
      end

      context 'when feed has no videos with published_at' do
        it 'renders pubDate as feed updated_at' do
          expect(xml.at_xpath('//channel/pubDate').text).to eq(feed.updated_at.rfc2822)
        end
      end
    end

    describe 'items (episodes)' do
      context 'with minimal video data' do
        let!(:video) do
          feed.videos.create!(
            url: 'https://youtube.com/watch?v=abc123',
            platform: 'youtube'
          )
        end

        before { get feed_path(feed, format: :xml) }

        it 'renders item with default title' do
          expect(xml.xpath('//item/title').first.text).to eq('Untitled')
        end

        it 'renders item link' do
          expect(xml.xpath('//item/link').first.text).to eq('https://youtube.com/watch?v=abc123')
        end

        it 'renders item description with CDATA' do
          description_node = xml.xpath('//item/description').first
          cdata_node = description_node.children.find { |child| child.is_a?(Nokogiri::XML::CDATA) }
          expect(cdata_node).not_to be_nil
          expect(description_node.text.strip).to eq('')
        end

        it 'renders item guid with video id' do
          guid_node = xml.xpath('//item/guid').first
          expect(guid_node.text).to eq(video.id)
          expect(guid_node['isPermaLink']).to eq('false')
        end

        it 'renders item pubDate as video created_at' do
          expect(xml.xpath('//item/pubDate').first.text).to eq(video.created_at.rfc2822)
        end

        it 'does not render itunes:image when thumbnail is blank' do
          expect(xml.xpath('//item/itunes:image', 'itunes' => 'http://www.itunes.com/dtds/podcast-1.0.dtd')).to be_empty
        end

        it 'does not render itunes:duration when duration is blank' do
          expect(xml.xpath('//item/itunes:duration', 'itunes' => 'http://www.itunes.com/dtds/podcast-1.0.dtd')).to be_empty
        end

        it 'does not render enclosure when no download exists' do
          expect(xml.xpath('//item/enclosure')).to be_empty
        end
      end

      context 'with complete video data' do
        let!(:video) do
          feed.videos.create!(
            url: 'https://youtube.com/watch?v=xyz789',
            platform: 'youtube',
            title: 'Episode 1: The Beginning',
            description: '<p>This is the <strong>first</strong> episode</p>',
            thumbnail: 'https://example.com/thumb.jpg',
            duration: '3600',
            published_at: 1.day.ago
          )
        end

        before { get feed_path(feed, format: :xml) }

        it 'renders item title' do
          expect(xml.xpath('//item/title').first.text).to eq('Episode 1: The Beginning')
        end

        it 'renders item description with HTML in CDATA' do
          expect(xml.xpath('//item/description').first.text.strip).to eq('<p>This is the <strong>first</strong> episode</p>')
        end

        it 'renders itunes:image' do
          image = xml.xpath('//item/itunes:image', 'itunes' => 'http://www.itunes.com/dtds/podcast-1.0.dtd').first
          expect(image['href']).to eq('https://example.com/thumb.jpg')
        end

        it 'renders itunes:duration' do
          expect(xml.xpath('//item/itunes:duration', 'itunes' => 'http://www.itunes.com/dtds/podcast-1.0.dtd').first.text).to eq('3600')
        end

        it 'renders item pubDate as video published_at' do
          expect(xml.xpath('//item/pubDate').first.text).to eq(video.created_at.rfc2822)
        end
      end

      context 'with download in pending status' do
        let!(:video) { feed.videos.create!(url: 'https://youtube.com/watch?v=pending', platform: 'youtube') }
        let!(:download) { video.create_download!(status: 'pending') }

        before { get feed_path(feed, format: :xml) }

        it 'does not render enclosure' do
          expect(xml.xpath('//item/enclosure')).to be_empty
        end
      end

      context 'with download in downloading status' do
        let!(:video) { feed.videos.create!(url: 'https://youtube.com/watch?v=downloading', platform: 'youtube') }
        let!(:download) { video.create_download!(status: 'downloading') }

        before { get feed_path(feed, format: :xml) }

        it 'does not render enclosure' do
          expect(xml.xpath('//item/enclosure')).to be_empty
        end
      end

      context 'with download in failed status' do
        let!(:video) { feed.videos.create!(url: 'https://youtube.com/watch?v=failed', platform: 'youtube') }
        let!(:download) { video.create_download!(status: 'failed') }

        before { get feed_path(feed, format: :xml) }

        it 'does not render enclosure' do
          expect(xml.xpath('//item/enclosure')).to be_empty
        end
      end

      context 'with completed download but no file attached' do
        let!(:video) { feed.videos.create!(url: 'https://youtube.com/watch?v=nofile', platform: 'youtube') }
        let!(:download) { video.create_download!(status: 'completed') }

        before { get feed_path(feed, format: :xml) }

        it 'does not render enclosure' do
          expect(xml.xpath('//item/enclosure')).to be_empty
        end
      end

      context 'with completed download and attached file' do
        let!(:video) { feed.videos.create!(url: 'https://youtube.com/watch?v=complete', platform: 'youtube') }
        let!(:download) { video.create_download!(status: 'completed') }

        before do
          download.file.attach(
            io: StringIO.new('fake audio content'),
            filename: 'episode.mp3',
            content_type: 'audio/mpeg'
          )
          get feed_path(feed, format: :xml)
        end

        it 'renders enclosure with url, length, and type' do
          enclosure = xml.xpath('//item/enclosure').first
          expect(enclosure).to be_present
          expect(enclosure['url']).to be_present
          expect(enclosure['length']).to eq(download.file.byte_size.to_s)
          expect(enclosure['type']).to eq('audio/mpeg')
        end
      end

      context 'with multiple videos' do
        let!(:video1) do
          feed.videos.create!(
            url: 'https://youtube.com/1',
            platform: 'youtube',
            title: 'Episode 1',
            published_at: 3.days.ago
          )
        end

        let!(:video2) do
          feed.videos.create!(
            url: 'https://youtube.com/2',
            platform: 'youtube',
            title: 'Episode 2',
            published_at: 2.days.ago
          )
        end

        let!(:video3) do
          feed.videos.create!(
            url: 'https://youtube.com/3',
            platform: 'youtube',
            title: 'Episode 3',
            published_at: 1.day.ago
          )
        end

        before { get feed_path(feed, format: :xml) }

        it 'renders all videos as items' do
          expect(xml.xpath('//item').count).to eq(3)
        end

        it 'orders items by published_at descending' do
          titles = xml.xpath('//item/title').map(&:text)
          expect(titles).to eq(['Episode 3', 'Episode 2', 'Episode 1'])
        end
      end

      context 'with videos without published_at' do
        let!(:video1) { feed.videos.create!(url: 'https://youtube.com/1', platform: 'youtube', title: 'First', created_at: 3.days.ago) }
        let!(:video2) { feed.videos.create!(url: 'https://youtube.com/2', platform: 'youtube', title: 'Second', created_at: 2.days.ago) }
        let!(:video3) { feed.videos.create!(url: 'https://youtube.com/3', platform: 'youtube', title: 'Third', created_at: 1.day.ago) }

        before { get feed_path(feed, format: :xml) }

        it 'orders items by created_at descending when published_at is null' do
          titles = xml.xpath('//item/title').map(&:text)
          expect(titles).to eq(['Third', 'Second', 'First'])
        end
      end
    end
  end

  describe ".show (JSON format)" do
    let(:feed) { Feed.create!(name: 'Test Podcast Feed') }
    let(:json) { JSON.parse(response.body) }

    before do
      get feed_path(feed, format: :json)
    end

    it 'returns successful JSON response' do
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('application/json')
    end

    describe 'feed data' do
      it 'includes feed id' do
        expect(json['id']).to eq(feed.id)
      end

      it 'includes feed name' do
        expect(json['name']).to eq('Test Podcast Feed')
      end

      it 'includes created_at timestamp' do
        expect(json['created_at']).to be_present
      end

      it 'includes updated_at timestamp' do
        expect(json['updated_at']).to be_present
      end

      it 'includes videos array' do
        expect(json['videos']).to be_an(Array)
      end
    end

    describe 'videos array' do
      context 'with no videos' do
        it 'returns empty array' do
          expect(json['videos']).to eq([])
        end
      end

      context 'with minimal video data' do
        let!(:video) do
          feed.videos.create!(
            url: 'https://youtube.com/watch?v=abc123',
            platform: 'youtube'
          )
        end

        before { get feed_path(feed, format: :json) }

        it 'includes video in array' do
          expect(json['videos'].length).to eq(1)
        end

        it 'includes video id' do
          expect(json['videos'][0]['id']).to eq(video.id)
        end

        it 'includes video url' do
          expect(json['videos'][0]['url']).to eq('https://youtube.com/watch?v=abc123')
        end

        it 'includes video platform' do
          expect(json['videos'][0]['platform']).to eq('youtube')
        end

        it 'includes null title' do
          expect(json['videos'][0]['title']).to be_nil
        end

        it 'includes null description' do
          expect(json['videos'][0]['description']).to be_nil
        end

        it 'includes null thumbnail' do
          expect(json['videos'][0]['thumbnail']).to be_nil
        end

        it 'includes null duration' do
          expect(json['videos'][0]['duration']).to be_nil
        end

        it 'includes null published_at' do
          expect(json['videos'][0]['published_at']).to be_nil
        end

        it 'includes created_at timestamp' do
          expect(json['videos'][0]['created_at']).to be_present
        end

        it 'includes updated_at timestamp' do
          expect(json['videos'][0]['updated_at']).to be_present
        end

        it 'includes null download when no download exists' do
          expect(json['videos'][0]['download']).to be_nil
        end
      end

      context 'with complete video data' do
        let!(:video) do
          feed.videos.create!(
            url: 'https://youtube.com/watch?v=xyz789',
            platform: 'youtube',
            title: 'Episode 1: The Beginning',
            description: 'This is the first episode',
            thumbnail: 'https://example.com/thumb.jpg',
            duration: '3600',
            published_at: 1.day.ago
          )
        end

        before { get feed_path(feed, format: :json) }

        it 'includes video title' do
          expect(json['videos'][0]['title']).to eq('Episode 1: The Beginning')
        end

        it 'includes video description' do
          expect(json['videos'][0]['description']).to eq('This is the first episode')
        end

        it 'includes video thumbnail' do
          expect(json['videos'][0]['thumbnail']).to eq('https://example.com/thumb.jpg')
        end

        it 'includes video duration' do
          expect(json['videos'][0]['duration']).to eq('3600')
        end

        it 'includes video published_at' do
          expect(json['videos'][0]['published_at']).to be_present
        end
      end

      context 'with download in pending status' do
        let!(:video) { feed.videos.create!(url: 'https://youtube.com/watch?v=pending', platform: 'youtube') }
        let!(:download) { video.create_download!(status: 'pending') }

        before { get feed_path(feed, format: :json) }

        it 'includes download object' do
          expect(json['videos'][0]['download']).to be_present
        end

        it 'includes download id' do
          expect(json['videos'][0]['download']['id']).to eq(download.id)
        end

        it 'includes download status' do
          expect(json['videos'][0]['download']['status']).to eq('pending')
        end

        it 'indicates no file attached' do
          expect(json['videos'][0]['download']['file_attached']).to eq(false)
        end

        it 'includes null file_url' do
          expect(json['videos'][0]['download']['file_url']).to be_nil
        end

        it 'includes null file_size' do
          expect(json['videos'][0]['download']['file_size']).to be_nil
        end

        it 'includes null file_content_type' do
          expect(json['videos'][0]['download']['file_content_type']).to be_nil
        end
      end

      context 'with completed download and attached file' do
        let!(:video) { feed.videos.create!(url: 'https://youtube.com/watch?v=complete', platform: 'youtube') }
        let!(:download) { video.create_download!(status: 'completed') }

        before do
          download.file.attach(
            io: StringIO.new('fake audio content'),
            filename: 'episode.mp3',
            content_type: 'audio/mpeg'
          )
          get feed_path(feed, format: :json)
        end

        it 'includes download object' do
          expect(json['videos'][0]['download']).to be_present
        end

        it 'includes download status' do
          expect(json['videos'][0]['download']['status']).to eq('completed')
        end

        it 'indicates file attached' do
          expect(json['videos'][0]['download']['file_attached']).to eq(true)
        end

        it 'includes file_url' do
          expect(json['videos'][0]['download']['file_url']).to be_present
          expect(json['videos'][0]['download']['file_url']).to include('episode.mp3')
        end

        it 'includes file_size' do
          expect(json['videos'][0]['download']['file_size']).to eq(download.file.byte_size)
        end

        it 'includes file_content_type' do
          expect(json['videos'][0]['download']['file_content_type']).to eq('audio/mpeg')
        end
      end

      context 'with multiple videos' do
        let!(:video1) do
          feed.videos.create!(
            url: 'https://youtube.com/1',
            platform: 'youtube',
            title: 'Episode 1',
            published_at: 3.days.ago
          )
        end

        let!(:video2) do
          feed.videos.create!(
            url: 'https://youtube.com/2',
            platform: 'youtube',
            title: 'Episode 2',
            published_at: 2.days.ago
          )
        end

        let!(:video3) do
          feed.videos.create!(
            url: 'https://youtube.com/3',
            platform: 'youtube',
            title: 'Episode 3',
            published_at: 1.day.ago
          )
        end

        before { get feed_path(feed, format: :json) }

        it 'includes all videos' do
          expect(json['videos'].length).to eq(3)
        end

        it 'orders videos by published_at descending' do
          titles = json['videos'].map { |v| v['title'] }
          expect(titles).to eq(['Episode 3', 'Episode 2', 'Episode 1'])
        end
      end

      context 'with videos without published_at' do
        let!(:video1) { feed.videos.create!(url: 'https://youtube.com/1', platform: 'youtube', title: 'First', created_at: 3.days.ago) }
        let!(:video2) { feed.videos.create!(url: 'https://youtube.com/2', platform: 'youtube', title: 'Second', created_at: 2.days.ago) }
        let!(:video3) { feed.videos.create!(url: 'https://youtube.com/3', platform: 'youtube', title: 'Third', created_at: 1.day.ago) }

        before { get feed_path(feed, format: :json) }

        it 'orders videos by created_at descending when published_at is null' do
          titles = json['videos'].map { |v| v['title'] }
          expect(titles).to eq(['Third', 'Second', 'First'])
        end
      end
    end
  end
end
