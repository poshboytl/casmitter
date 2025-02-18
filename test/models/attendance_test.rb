require "test_helper"

class AttendanceTest < ActiveSupport::TestCase
  def setup
    @episode = Episode.create
    @guest = Guest.create
    @host = Host.create

    @attendance = Attendance.new
    @attendance.attendee = @guest
    @attendance.episode = @episode
    @attendance.save

    @attendance_with_host = Attendance.new
    @attendance_with_host.attendee = @host
    @attendance_with_host.episode = @episode
    @attendance_with_host.save

  end

  test "Attendance should be set correctly" do
    assert_equal @episode, @attendance.episode
    assert_equal @guest, @attendance.attendee
  end

  test "#guest method should return guest if it has one" do
    assert_equal @guest, @attendance.guest
  end

  test "#guest method should return nil if it doesn't have one" do
    assert_nil Attendance.create.guest
  end

  test "#host method should return guest if it has one" do
    assert_equal @host, @attendance_with_host.host
  end

  test "#host method should return nil if it doesn't have one" do
    assert_nil Attendance.create.host
  end

end
