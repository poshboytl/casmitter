class Attendance < ApplicationRecord
  enum :role,  host: 0, guest: 1

  belongs_to :attendee
  belongs_to :episode

  def guest
    attendee.is_a?(Guest) ? attendee : nil
  end

  def host
    attendee.is_a?(Host) ? attendee : nil
  end
end
