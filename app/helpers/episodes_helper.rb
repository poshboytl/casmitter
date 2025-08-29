module EpisodesHelper
  def format_episode_duration_and_date(episode)
    date = episode&.published_at&.strftime("%Y-%m-%d")
    hours = (episode.duration || 0) / 3600
    minutes = ((episode.duration || 0) % 3600) / 60
    
    duration = if hours.zero?
      "#{minutes} mins"
    else
      "#{hours} hr #{minutes} mins"
    end

    "#{date} | #{duration}"
  end
end
