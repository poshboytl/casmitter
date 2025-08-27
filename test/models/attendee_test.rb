require "test_helper"

class AttendeeTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  def setup
    @host = attendees(:jason)
    @guest = attendees(:kevin)
  end

  test "create Host" do
    assert_equal 'Host', @host.class.name
  end

  test "create Guest" do
    assert_equal 'Guest', @guest.class.name
  end

  test "social links with correct structure" do
    @host.social_links = { weibo: "https://weibo.com/u/1234567890", twitter: "https://twitter.com/username" }
    assert_equal true, @host.valid?
  end

  test "social links with incorrect structure" do
    @host.social_links = { weibo: "https://weibo.com/u/1234567890", twitter: "invalid_url" }
    assert_equal false, @host.valid?
    assert_equal "must be a valid URL for twitter", @host.errors[:social_links].first
  end

  test "social links url is digits" do
    @host.social_links = { X: 1234567890 }
    assert_equal false, @host.valid?
    assert_equal "URL for X must be a string", @host.errors[:social_links].last
  end
end
