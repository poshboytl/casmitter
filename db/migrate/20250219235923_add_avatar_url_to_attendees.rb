class AddAvatarUrlToAttendees < ActiveRecord::Migration[8.0]
  def change
    add_column :attendees, :avatar_url, :string
  end
end
