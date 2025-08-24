class Admin::EpisodesController < Admin::BaseController
  def index
    @episodes = Episode.order(number: :desc, created_at: :desc).page(params[:page]).per(2)
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

  def edit
    @episode = Episode.find(params[:id])
  end

  def update
    @episode = Episode.find(params[:id])
    
    if @episode.update(episode_params)
      redirect_to admin_episodes_path, notice: 'Episode was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @episode = Episode.find(params[:id])
    @episode.destroy
    
    redirect_to admin_episodes_path, notice: 'Episode was successfully deleted.'
  end

  private

  def episode_params
    params.require(:episode).permit(:name, :summary, :desc, :keywords, :number, :slug, :duration, :cover_url, :status, :file_uri, :length, :published_at)
  end
end
