xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0",
    "xmlns:itunes" => "http://www.itunes.com/dtds/podcast-1.0.dtd",
    "xmlns:content" => "http://purl.org/rss/1.0/modules/content/",
    "xmlns:googleplay" => "http://www.google.com/schemas/play-podcasts/1.0" do
  xml.channel do
    # 播客基本信息
    # TODO: change to the real information
    xml.title "你的播客名称"
    xml.link root_url
    xml.language "zh-CN"
    xml.copyright "Copyright #{Time.current.year}"
    xml.pubDate Time.current.to_fs(:rfc822)
    xml.lastBuildDate @episodes.first.created_at.to_fs(:rfc822)
    xml.description "你的播客描述"
    
    # iTunes 特定标签
    # TODO: change to the real information
    xml.tag!("itunes:author", "主播名称")
    xml.tag!("itunes:type", "episodic")
    xml.tag!("itunes:owner") do
      xml.tag!("itunes:name", "你的名字")
      xml.tag!("itunes:email", "your@email.com")
    end
    xml.tag!("itunes:image", href: "你的播客封面图片URL")
    xml.tag!("itunes:category", text: "Technology") do
      xml.tag!("itunes:category", text: "Software How-To")
    end
    xml.tag!("itunes:explicit", "false")

    # 遍历所有集数
    @episodes.each do |episode|
      xml.item do
        xml.title episode.name
        xml.description episode.desc
        xml.pubDate episode.created_at.to_fs(:rfc822)
        xml.enclosure url: episode.file_uri, 
                     length: "0",  # 这里需要填入文件大小（字节）
                     type: "audio/mpeg"
        xml.guid episode.file_uri
        xml.link episode_url(episode)
        
        # iTunes 特定的集数信息
        xml.tag!("itunes:title", episode.name)
        xml.tag!("itunes:author", "主播名称")
        xml.tag!("itunes:duration", "00:00:00") # 需要填入实际时长
        xml.tag!("itunes:summary", episode.summary)
        xml.tag!("itunes:explicit", "false")
        xml.tag!("itunes:episodeType", "full")
      end
    end
  end
end 