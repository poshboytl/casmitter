class AddUniqueIndexToEpisodeNumber < ActiveRecord::Migration[8.0]
  def change
    # Add partial unique index: only published episodes need unique numbers
    add_index :episodes, :number, unique: true, where: "status = 1", name: "index_episodes_on_number_published"
  end
end
