class AddRollToAttendances < ActiveRecord::Migration[8.0]
  def change
    add_column :attendances, :role, :integer
  end
end
