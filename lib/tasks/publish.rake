require_relative '../file_utils'

namespace :publish do
  desc "Publish episode 2"
  task episode_2: :environment do
    terry = Host.find_by(name: "Terry Tai")
    jan = Host.find_by(name: "Jan Xie")
    howard = Host.find_by(name: "Howard Ye")
    file_uri = "https://assets.teahour.dev/teahour2_2.mp3"
    file_size = FileUtils.get_remote_file_size(file_uri)
    puts "File size: #{file_size} bytes"

    episode_2 = Episode.create!(
      name: "昨天，今天，明天",
      file_uri: file_uri,
      summary: "本期节目是 「Teahour 2.0 来了！(下)」 ，新主播们继续摆龙门阵, 聊聊科技的昨天，今天，明天（BTW,明天没来得及聊）。",
      desc: File.read(Rails.root.join('db', 'seeds', 'episode_2_desc.md')),
      status: 1,
      keywords: 'podcast, ai, web2',
      number: 2,
      slug: '2',
      duration: 4434,
      published_at: Time.zone.now,
      cover_url: "https://assets.teahour.dev/teahour2-logo.jpg",
      length: file_size
    )

    puts "Creating attendances..."
    Attendance.create!(attendee: terry, episode: episode_2, role: 0)
    Attendance.create!(attendee: jan, episode: episode_2, role: 1)
    Attendance.create!(attendee: howard, episode: episode_2, role: 1)

    puts "Episode 2 published!"

  end

  desc "Delete episode 2"
  task delete_episode_2: :environment do
    episode_2 = Episode.find_by(number: 2)
    Attendance.where(episode: episode_2).destroy_all
    episode_2.destroy
    puts "Episode 2 deleted!"
  end

  desc "Publish Episode 3" 
  task episode_3: :environment do
    terry = Host.find_by(name: "Terry Tai")
    jan = Host.find_by(name: "Jan Xie")
    howard = Host.find_by(name: "Howard Ye")
    kai = Guest.find_by(name: "Kai") || Guest.create!(name: "Kai", avatar_url: "https://assets.teahour.dev/kai-avatar.jpg", social_links: {'X' => 'https://x.com/_kaichen' })
    file_uri = "https://assets.teahour.dev/teahour2_3.mp3"
    file_size = FileUtils.get_remote_file_size(file_uri)
    puts "File size: #{file_size} bytes"

    episode_3 = Episode.create!(
      name: "程序员的存在主义危机（上）",
      file_uri: file_uri,
      summary: "AI 技术席卷而来的浪潮如何重塑程序员的职业与人生，程序员们正面临前所未有的存在主义危机？ 又或者是机遇？这一期我们邀请到好友 Kai, 冲上一杯好茶，我们一起来探讨一下这个话题。",
      desc: File.read(Rails.root.join('db', 'seeds', 'episode_3_desc.md')),
      status: 1,
      keywords: 'ai, programmer, developer, career, philosophy',
      number: 3,
      slug: '3',
      duration: 10228,
      published_at: Time.zone.now,
      cover_url: "https://assets.teahour.dev/teahour2-ep3-cover.png",
      length: file_size
    )

    puts "Creating attendances..."
    Attendance.create!(attendee: terry, episode: episode_3, role: 0)
    Attendance.create!(attendee: jan, episode: episode_3, role: 0)
    Attendance.create!(attendee: howard, episode: episode_3, role: 0)
    Attendance.create!(attendee: kai, episode: episode_3, role: 1)

    puts "Episode 3 published!"

  end

  desc "Delete Episode 3" 
  task delete_episode_3: :environment do
    episode_3 = Episode.find_by(number: 3)
    Attendance.where(episode: episode_3).destroy_all
    episode_3.destroy
    puts "Episode 3 deleted!"
  end

end
