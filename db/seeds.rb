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
  avatar_url: "https://assets.teahour.dev/howard-avatar2.jpg",
  social_links: { "X" => "https://x.com/hayeah" }
)

puts "Creating guests..."
# Creating guests here 



puts "Creating episodes..."


require_relative '../lib/file_utils'
file_uri = "https://assets.teahour.dev/teahour2_1.mp3"
file_size = FileUtils.get_remote_file_size(file_uri)
puts "File size: #{file_size} bytes"

episode_1 = Episode.create!(
  name: "Teahour 2.0 来了！",
  file_uri: file_uri,
  summary: "12 年前 Teahour 诞生, 12 年后的今天 Teahour 2.0 来了！这一期，新主播们一起摆摆龙门阵。-- Teahour 2.0 是一档针对程序员播客节目，更是一场思维的探索。 程序不仅仅是工具，它是开发者表达思想、塑造未来的媒介。 我们相信，黑客精神不仅关乎技术，还关乎突破边界、打破规则、重新定义世界。",
  desc: File.read(Rails.root.join('db', 'seeds', 'episode_1_desc.md')),
  status: 1,
  keywords: 'podcast, programmer',
  number: 1,
  slug: '1',
  duration: 7242,
  published_at: Time.zone.now,
  cover_url: "https://assets.teahour.dev/teahour2-logo.jpg",
  length: file_size
)



puts "Creating attendances..."
Attendance.create!(attendee: terry, episode: episode_1, role: 0)
Attendance.create!(attendee: jan, episode: episode_1, role: 1)
Attendance.create!(attendee: howard, episode: episode_1, role: 1)


puts "Seeding completed!"
