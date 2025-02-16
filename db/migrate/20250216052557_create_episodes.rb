class CreateEpisodes < ActiveRecord::Migration[8.0]
  def change
    create_table :episodes do |t|
      t.string :name
      t.string :file_uri
      t.text :desc

      t.timestamps
    end
  end
end
