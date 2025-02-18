class CreateAttendances < ActiveRecord::Migration[8.0]
  def change
    create_table :attendances do |t|
      t.integer :attendee_id
      t.integer :episode_id

      t.timestamps
    end
  end
end
