class AddCoverUrlToEpisodes < ActiveRecord::Migration[8.0]
  def change
    add_column :episodes, :cover_url, :string
  end
end
