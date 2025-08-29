class EpisodesController < ApplicationController
  before_action :set_episode, only: %i[ show ]

  # GET /episodes or /episodes.json
  def index
    @episodes = Episode.published.order(number: :desc)
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
      @episode = Episode.published.find_by(slug: params.expect(:id)) || 
                 Episode.published.find_by(number: params.expect(:id)) ||
                 Episode.preview.find_by(preview_token: params.expect(:id))
      raise ActionController::RoutingError.new('Not Found') unless @episode
    end

    # Only allow a list of trusted parameters through.
    def episode_params
      params.expect(episode: [ :name, :file_uri, :desc ])
    end
end
