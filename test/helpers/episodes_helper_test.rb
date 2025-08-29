require "test_helper"
require "ostruct"

class EpisodesHelperTest < ActionView::TestCase
  test "formats episode with hours and minutes correctly" do
    episode = OpenStruct.new(
      published_at: Time.zone.parse('2024-03-20'),
      duration: 5400  # 1 hour 30 minutes
    )

    assert_equal "2024-03-20 | 1 hr 30 mins", format_episode_duration_and_date(episode)
  end

  test "formats episode with exactly one hour correctly" do
    episode = OpenStruct.new(
      published_at: Time.zone.parse('2024-03-20'),
      duration: 3600  # 1 hour
    )

    assert_equal "2024-03-20 | 1 hr 0 mins", format_episode_duration_and_date(episode)
  end

  test "formats episode with only minutes correctly" do
    episode = OpenStruct.new(
      published_at: Time.zone.parse('2024-03-20'),
      duration: 1800  # 30 minutes
    )

    assert_equal "2024-03-20 | 30 mins", format_episode_duration_and_date(episode)
  end
end 