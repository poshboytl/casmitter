class Admin::EpisodesController < Admin::BaseController
  def index
    @episodes = Episode.order(number: :desc, created_at: :desc).page(params[:page]).per(2)
  end

  def new
    @episode = Episode.new
    @suggested_number = Episode.next_available_number
  end

  def create
    @episode = Episode.new(episode_params)
    
    if @episode.save
      redirect_to admin_episodes_path, notice: 'Episode was successfully created.'
    else
      @suggested_number = Episode.next_available_number
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @episode = Episode.find(params[:id])
    @suggested_number = @episode.draft? ? Episode.next_available_number : @episode.number
  end

  def update
    @episode = Episode.find(params[:id])
    
    if @episode.update(episode_params)
      redirect_to admin_episodes_path, notice: 'Episode was successfully updated.'
    else
      @suggested_number = @episode.draft? ? Episode.next_available_number : @episode.number
      render :edit, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    @episode.errors.add(:number, "has already been used by another published episode")
    @suggested_number = Episode.next_available_number
    render :edit, status: :unprocessable_entity
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
