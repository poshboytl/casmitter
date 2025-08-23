class Admin::AttendeesController < Admin::BaseController
  def index
    @attendees = Attendee.order(created_at: :desc)
  end
end
