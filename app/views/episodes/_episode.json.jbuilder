json.extract! episode, :id, :name, :file_uri, :desc, :created_at, :updated_at
json.url episode_url(episode, format: :json)
