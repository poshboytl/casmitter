require "test_helper"

class AttendeeTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  def setup
    @host = Host.new
    @guest = Guest.new
  end

  test "create Host" do
    assert_equal 'Host', @host.class.name
  end

  test "create Guest" do
    assert_equal 'Guest', @guest.class.name
  end

  test "social links" do
    attendee = Attendee.new
    attendee.social_links = { weibo: "https://weibo.com/u/1234567890", twitter: "https://twitter.com/username" }
    attendee.save
    assert_equal "https://weibo.com/u/1234567890", attendee.social_links[:weibo]
  end

end
