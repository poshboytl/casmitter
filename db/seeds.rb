# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end


terry = Host.create(name: "Terry Tai", bio: "Co-Host of Teahour", desc: "写代码为生，并以此为乐。")

guest = Guest.create(name: 'Jan Xie', bio: "Nervos Co-Founder", desc: "行到水穷处，坐看云起时。")

episode_82 = Episode.new(
  name: "聊聊比特币背后的技术和 Blockchain",
  file_uri: "https://aphid.fireside.fm/d/1437767933/635ad9f1-6ce0-4f31-84cf-030e0c949169/59aa7276-9eff-416d-b10c-31b37592dcd3.mp3",
  summary: '本期由 Terry 主持, 请到了他的最好基友 Jan, 和他聊聊比特币背后的技术, 分布式系统, 算法以及Blockchain.',
  desc: "a long desc",
  status: 1,
  keywords: 'blockchain, bitcoin',
  number: 82,
  slug: '82'
)

Attendance.create(attendee: terry, episode: episode_82, role: 0)
Attendance.create(attendee: guest, episode: episode_82, role: 1)
