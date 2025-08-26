require "test_helper"

class EpisodeTest < ActiveSupport::TestCase
  test "should get summary with desc" do
    episode = episodes(:ep1)
    assert_includes episode.summary_with_desc, "<p>#{episode.summary}</p>"
    assert_includes episode.summary_with_desc, "<br><br>"
    assert_includes episode.summary_with_desc, "<ul>"
    assert_includes episode.summary_with_desc, "</ul>"
    assert_includes episode.summary_with_desc, "<li>"
    assert_includes episode.summary_with_desc, "</li>"
  end

  test "should get duration in hours" do
    episode = episodes(:ep1)
    assert_equal "02:00:42", episode.duration_in_hours
  end

  test "should get host names" do
    episode = episodes(:ep1)
    assert_equal "Jason, Kevin", episode.attendee_names
  end

  test "the number should +1" do
    max = Episode.maximum(:number)
    episode = Episode.new(name: "Hello World! again!", slug: 'hwa')
    assert_equal max, Episode.maximum(:number)
    episode.update status: :published
    assert_equal max + 1, Episode.maximum(:number)
  end

  test "should auto-assign published_at when status changes to published" do
    episode = Episode.new(name: "Test Episode", slug: 'test-episode')
    
    # Initially published_at should be nil
    assert_nil episode.published_at
    
    # Change status to published
    episode.update status: :published
    
    # published_at should now be automatically assigned
    assert_not_nil episode.published_at
    assert_in_delta Time.current, episode.published_at, 2.seconds
  end

  test "should not override published_at if already set" do
    original_time = 1.day.ago
    episode = Episode.new(name: "Test Episode", slug: 'test-episode', published_at: original_time)
    
    # published_at should be the original time (use assert_in_delta to handle precision issues)
    assert_in_delta original_time, episode.published_at, 1.second
    
    # Change status to published
    episode.update status: :published
    
    # published_at should remain unchanged
    # Since database truncates microseconds, we compare the time to the minute to avoid precision issues
    assert_equal original_time.change(usec: 0, sec: 0), episode.published_at.change(usec: 0, sec: 0)
  end

  test "should auto-assign both number and published_at when both are blank" do
    episode = Episode.new(name: "Test Episode", slug: 'test-episode')
    
    # Initially both should be nil
    assert_nil episode.number
    assert_nil episode.published_at
    
    # Change status to published
    episode.update status: :published
    
    # Both should now be automatically assigned
    assert_not_nil episode.number
    assert_not_nil episode.published_at
    assert_in_delta Time.current, episode.published_at, 2.seconds
  end
end
