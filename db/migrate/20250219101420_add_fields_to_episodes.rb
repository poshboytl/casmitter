class AddFieldsToEpisodes < ActiveRecord::Migration[8.0]
  def change
    add_column :episodes, :number, :integer, null: false, default: 999
    add_column :episodes, :slug, :string
  end
end
