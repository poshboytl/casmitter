class Admin::EpisodesController < ApplicationController
  layout 'admin'
  before_action :require_admin_authentication

  def index
    @episodes = Episode.order(created_at: :desc)
  end

  def new
    @episode = Episode.new
  end

  def create
    @episode = Episode.new(episode_params)
    
    if @episode.save
      redirect_to admin_episodes_path, notice: 'Episode was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def require_admin_authentication
    unless authenticated? && Current.user
      redirect_to new_session_path, alert: "Admin access required"
    end
  end

  def episode_params
    params.require(:episode).permit(:name, :summary, :desc, :keywords, :number, :slug, :duration, :cover_url, :status, :file_uri, :length, :published_at)
  end
end
