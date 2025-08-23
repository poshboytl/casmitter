class Admin::AttendeesController < Admin::BaseController
  def index
    @attendees = Attendee.order(created_at: :desc).page(params[:page]).per(20)
  end
end
