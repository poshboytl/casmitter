class Attendance < ApplicationRecord
  belongs_to :attendee
  belongs_to :episode

  def guest
    attendee.is_a?(Guest) ? attendee : nil
  end

  def host
    attendee.is_a?(Host) ? attendee : nil
  end
end
