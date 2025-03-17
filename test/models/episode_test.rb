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
end
