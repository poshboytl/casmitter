puts "Deleting all records..."
Attendance.delete_all
Episode.delete_all
Guest.delete_all
Host.delete_all

puts "Creating hosts..."
terry = Host.create!(name: "Terry Tai", bio: "Co-Host of Teahour, Nervos Co-Founder", desc: "写代码为生，并以此为乐。",
  avatar_url: "https://assets.teahour.dev/terry-avatar.jpg",
  social_links: { "X" => "https://x.com/poshboytl", "Mastodon" => "https://mastodon.social/@poshboytl",  "Bluesky" => "https://bsky.app/profile/terrytai.bsky.social"}
)

jan = Host.create!(name: 'Jan Xie', bio: "Co-Host of Teahour, Nervos Co-Founder", desc: "行到水穷处，坐看云起时。",
  avatar_url: "https://assets.teahour.dev/jan-avatar.jpg",
  social_links: { "X" => "https://x.com/busyforking" }
)

howard = Host.create!(name: 'Howard Ye', bio: "Co-Host of Teahour", desc: "if you do not construct your reality, your reality with be constructed for you",
  avatar_url: "https://assets.teahour.dev/howard-avatar.jpg",
  social_links: { "X" => "https://x.com/hayeah" }
)

puts "Creating guests..."
dongxu = Guest.create!(name: 'Dongxu Huang', bio: "PingCAP CTO", desc: "", 
  avatar_url: "https://media24.fireside.fm/file/fireside-images-2024/podcasts/images/6/635ad9f1-6ce0-4f31-84cf-030e0c949169/guests/1/15dcb1de-132c-4866-865d-bc4aec172db4/avatar_small.jpg?v=0",
  social_links: {}
)




puts "Creating episodes..."

episode_79 = Episode.create!(
  name: "隐居大理钻研技术的 hacker",
  file_uri: "https://assets.teahour.dev/teahour79.mp3",
  summary: '本期由 Terry 主持，采访到了 思客教学 的创始人 Howard。 他生于台湾，学在加拿大，边环游世界边 coding, 现在隐居大理钻研技术和做教学。 和这样酷酷的 hacker 聊聊 Web 前后端技术趋势以及技术教学，还有他酷酷的生活。',
  desc: "a long desc",
  status: 1,
  keywords: 'remote, lifestyle, coding',
  number: 79,
  slug: '79',
  published_at: DateTime.parse('2015-08-31 14:00:00'),
  duration: 6540,
  cover_url: "https://assets.teahour.dev/dl2.jpg"
)

episode_82 = Episode.create!(
  name: "聊聊比特币背后的技术和 Blockchain",
  file_uri: "https://assets.teahour.dev/teahour82.mp3",
  summary: '本期由 Terry 主持, 请到了他的最好基友 Jan, 和他聊聊比特币背后的技术, 分布式系统, 算法以及Blockchain.',
  desc: "a long desc",
  status: 1,
  keywords: 'blockchain, bitcoin',
  number: 82,
  slug: '82',
  published_at: DateTime.parse('2015-12-27 14:00:00'),
  duration: 7879,
  cover_url: "https://logos-world.net/wp-content/uploads/2020/08/Bitcoin-Logo.png"
)

episode_90 = Episode.create!(
  name: "和 PingCAP CTO 畅谈数据库和编程语言",
  file_uri: "https://assets.teahour.dev/teahour90.mp3",
  summary: '本期节目我们邀请到了 PingCAP CTO 黄东旭, 和他一起探讨一下关于数据库以及 NewSQL 的话题。 当然我们还好好聊了聊 Go 和 Rust，干货十足，不容错过！',
  desc: "a long desc",
  status: 1,
  keywords: 'database, newsql, go, rust',
  number: 90,
  slug: '90',
  published_at: DateTime.parse('2017-11-22 14:00:00'),
  duration: 10799,
  cover_url: "https://assets.teahour.dev/tidb.jpeg"
)



puts "Creating attendances..."
Attendance.create!(attendee: terry, episode: episode_82, role: 0)
Attendance.create!(attendee: jan, episode: episode_82, role: 1)

Attendance.create!(attendee: terry, episode: episode_79, role: 0)
Attendance.create!(attendee: howard, episode: episode_79, role: 1)

Attendance.create!(attendee: terry, episode: episode_90, role: 0)
Attendance.create!(attendee: dongxu, episode: episode_90, role: 1)

puts "Seeding completed!"
