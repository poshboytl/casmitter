class AddPublishedAtAndDurationToEpisodes < ActiveRecord::Migration[8.0]
  def change
    add_column :episodes, :published_at, :datetime
    add_column :episodes, :duration, :integer
  end
end
