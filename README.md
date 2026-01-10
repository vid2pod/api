# vid2pod
The rails json API for vid2pod.fm, a tool that converts video links (i.e. youtube, tiktok etc) into podcast rss files so you can consume these videos as podcasts in your favorite podcast player.

## yt-dlp cookies
This app uses yt-dlp buildpacks on heroku to download the audio from youtube. We use actual user account cookie data to make this more reliable. To generate new cookie data please do the following:

please don't use your own personal youtube accoun personal youtube account.

### 1. Export YouTube Cookies

You'll need to export cookies from your browser:

Install a browser extension:
- Chrome/Edge: "Get cookies.txt LOCALLY"
- Firefox: "cookies.txt"

Steps:
1. Visit youtube.com and sign in
2. Use the extension to export cookies in Netscape format
3. Save the output to a file (e.g., credentials/www.youtube.com-cookies.txt)

### 2. Set Heroku Environment Variable

`heroku config:set YOUTUBE_COOKIES="$(cat credentials/www.youtube.com-cookies.txt)"`


## RSS
rss requirements:
https://podcasters.apple.com/support/823-podcast-requirements#:~:text=RSS%20feed%20URLs%20must%20adhere,tags%20in%20podcast%20RSS%20feeds.

heres an example rss feed: in the vendor/maintenance-phase.xml


## Marketing
https://www.reddit.com/r/podcasts/comments/1lhm3oy/youtube_videos_as_podcasts/


# TODO
- [x] Play a sound or a tone at the beginning and end of each podcast.
- [ ] have a voice announce the title, author and duration of a video.
- [ ] Setup bookmarklet
- [ ] Add favicon
- [ ] Add Image for xml feed for channel
