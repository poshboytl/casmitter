class EpisodesController < ApplicationController
  before_action :set_episode, only: %i[ show ]

  # GET /episodes or /episodes.json
  def index
    @episodes = Episode.all.order(created_at: :desc)
    @hosts = Host.all

    respond_to do |format|
      format.html
      format.rss do
        render layout: false, content_type: 'application/xml'
      end
    end
  end

  # GET /episodes/1 or /episodes/1.json
  def show
    @hosts = @episode.hosts
    @guests = @episode.guests
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_episode
      @episode = Episode.find_by(slug: params.expect(:id)) || Episode.find_by(number: params.expect(:id))
      raise ActionController::RoutingError.new('Not Found') unless @episode
    end

    # Only allow a list of trusted parameters through.
    def episode_params
      params.expect(episode: [ :name, :file_uri, :desc ])
    end
end
