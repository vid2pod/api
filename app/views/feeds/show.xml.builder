xml.instruct!
xml.tag!('rss',
  version: '2.0',
  'xmlns:itunes' => 'http://www.itunes.com/dtds/podcast-1.0.dtd',
  'xmlns:content' => 'http://purl.org/rss/1.0/modules/content/',
  'xmlns:podcast' => 'https://podcastindex.org/namespace/1.0',
  'xmlns:atom' => 'http://www.w3.org/2005/Atom',
  'xmlns:googleplay' => 'http://www.google.com/schemas/play-podcasts/1.0'
) do
  xml.channel do
    # Channel metadata
    xml.title 'vid2pod.fm video feed'
    xml.link url_for(controller: 'feeds', action: 'show', id: @feed.id, format: :xml, only_path: false)
    xml.description "the videos that the user has added to their vid2pod.fm feed"
    xml.tag!('atom:link',
      href: url_for(controller: 'feeds', action: 'show', id: @feed.id, format: :xml, only_path: false),
      rel: 'self',
      type: 'application/rss+xml'
    )

    # iTunes metadata
    xml.tag!('itunes:type', 'episodic')
    xml.tag!('itunes:author', @feed.name)
    xml.tag!('itunes:explicit', 'false')

    # Language and dates
    xml.language 'en-US'
    xml.pubDate @feed.videos.maximum(:published_at)&.rfc2822 || @feed.updated_at.rfc2822
    xml.lastBuildDate @feed.updated_at.rfc2822
    xml.generator 'vid2pod'

    # Episodes (items)
    @videos.each do |video|
      xml.item do
        xml.title video.title || 'Untitled'
        xml.link video.url

        # iTunes episode metadata
        xml.tag!('itunes:image', href: video.thumbnail) if video.thumbnail.present?
        xml.tag!('itunes:duration', video.duration) if video.duration.present?

        # Description
        xml.description { xml.cdata!(video.description || '') }

        # Enclosure (audio redirect to YouTube)
        xml.enclosure(
          url: audio_video_url(video, host: ENV['APP_HOST'] || request.host),
          length: video.estimated_file_size,
          type: 'audio/mpeg'
        )

        # GUID and publish date
        xml.guid video.id, isPermaLink: 'false'
        xml.pubDate (video.published_at || video.created_at).rfc2822
      end
    end
  end
end
