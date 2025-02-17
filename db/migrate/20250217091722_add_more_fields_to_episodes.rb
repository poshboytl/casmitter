class AddMoreFieldsToEpisodes < ActiveRecord::Migration[8.0]
  def change
    add_column :episodes, :summary, :string
    add_column :episodes, :status, :integer, default: 0, null: false
    add_column :episodes, :keywords, :string
  end
end
