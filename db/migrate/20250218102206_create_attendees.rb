class CreateAttendees < ActiveRecord::Migration[8.0]
  def change
    create_table :attendees do |t|
      t.string :type
      t.string :name
      t.text :desc
      t.string :bio

      t.timestamps
    end
  end
end
