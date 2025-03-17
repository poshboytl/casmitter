xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0",
    "xmlns:itunes" => "http://www.itunes.com/dtds/podcast-1.0.dtd",
    "xmlns:content" => "http://purl.org/rss/1.0/modules/content/",
    "xmlns:googleplay" => "http://www.google.com/schemas/play-podcasts/1.0" do
  xml.channel do
    # podcast basic information
    xml.title "Teahour 2.0"
    xml.link "https://teahour.dev/"
    xml.language "zh-CN"
    xml.copyright "Copyright #{Time.current.year} Teahour 2.0"
    xml.pubDate Episode.published.minimum(:published_at).to_fs(:rfc822)
    xml.lastBuildDate Episode.published.maximum(:published_at).to_fs(:rfc822)
    xml.description "Teahour 2.0 是一档针对程序员播客节目，更是一场思维的探索。 程序不仅仅是工具，它是开发者表达思想、塑造未来的媒介。 我们相信，黑客精神不仅关乎技术，还关乎突破边界、打破规则、重新定义世界。"
    
    # iTunes tags
    xml.tag!("itunes:author", "Terry Tai, Jan Xie, Howard Ye")
    xml.tag!("itunes:type", "episodic")
    xml.tag!("itunes:owner") do
      xml.tag!("itunes:name", "Terry Tai")
      xml.tag!("itunes:email", "t@teahour.dev")
    end
    xml.tag!("itunes:image", href: "https://assets.teahour.dev/teahour-logo-apple.png")
    xml.tag!("itunes:category", text: "Technology")
    xml.tag!("itunes:explicit", "false")

    @episodes.each do |episode|
      xml.item do
        xml.title episode.name
        xml.description  do
          xml.cdata! episode.summary_with_desc
        end
        xml.pubDate episode.published_at.to_fs(:rfc822)
        xml.enclosure url: episode.file_uri, 
                     length: episode.length, 
                     type: "audio/mpeg"
        xml.guid episode.file_uri
        xml.link episode_url(episode)
        
        # iTunes tags
        xml.tag!("itunes:title", episode.name)
        xml.tag!("itunes:author", episode.attendee_names)
        xml.tag!("itunes:duration", episode.duration_in_hours)
        xml.tag!("itunes:summary", episode.summary)
        xml.tag!("itunes:explicit", "false")
        xml.tag!("itunes:episodeType", "full")
      end
    end
  end
end 