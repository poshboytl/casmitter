class Admin::AttendeesController < Admin::BaseController
  before_action :set_attendee, only: [:show, :edit, :update, :destroy]

  def index
    @attendees = Attendee.order(created_at: :desc).page(params[:page]).per(20)
    @hosts = Host.order(created_at: :desc)
    @guests = Guest.order(created_at: :desc)
  end

  def show
  end

  def new
    @attendee = Attendee.new
    @attendee.type = params[:type] if params[:type].present? && %w[Host Guest].include?(params[:type])
  end

  def create
    @attendee = attendee_class.new(attendee_params)
    
    if @attendee.save
      redirect_to admin_attendees_path, notice: "#{@attendee.type || 'Attendee'} was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @attendee.update(attendee_params)
      redirect_to admin_attendee_path(@attendee), notice: "#{@attendee.type || 'Attendee'} was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    attendee_type = @attendee.type || 'Attendee'
    @attendee.destroy
    redirect_to admin_attendees_path, notice: "#{attendee_type} was successfully deleted."
  end

  private

  def set_attendee
    @attendee = Attendee.find(params[:id])
  end

  def attendee_params
    # Determine the correct parameter key based on the attendee type
    param_key = @attendee&.class&.name&.downcase || 
                params[:attendee]&.dig(:type)&.downcase || 
                params[:guest] ? 'guest' : 
                params[:host] ? 'host' : 
                'attendee'
    
    Rails.logger.info("Using param key: #{param_key}")
    Rails.logger.info("Available params keys: #{params.keys}")
    
    permitted_params = params.require(param_key.to_sym).permit(:type, :name, :desc, :bio, :avatar_url, :social_links)
    
    # Parse social_links from JSON string if it's present
    if permitted_params[:social_links].present?
      begin
        permitted_params[:social_links] = JSON.parse(permitted_params[:social_links])
      rescue JSON::ParserError
        # If JSON parsing fails, set to empty hash
        permitted_params[:social_links] = {}
      end
    end
    
    Rails.logger.info("permitted_params: #{permitted_params.inspect}")
    permitted_params
  end

  def attendee_class
    # Get type from any available parameter source
    type_value = params.dig(:attendee, :type) || 
                 params.dig(:guest, :type) || 
                 params.dig(:host, :type)
    
    case type_value
    when 'Host'
      Host
    when 'Guest'
      Guest
    else
      Attendee
    end
  end
end
