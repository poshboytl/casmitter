class AddLengthToEpisodes < ActiveRecord::Migration[8.0]
  def change
    add_column :episodes, :length, :integer
  end
end
