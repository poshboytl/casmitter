class AddPreviewTokenToEpisodes < ActiveRecord::Migration[8.0]
  def change
    add_column :episodes, :preview_token, :string
    add_index :episodes, :preview_token, unique: true
  end
end
