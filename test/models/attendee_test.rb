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

end
