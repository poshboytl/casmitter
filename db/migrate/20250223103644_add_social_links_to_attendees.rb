class AddSocialLinksToAttendees < ActiveRecord::Migration[8.0]
  def change
    add_column :attendees, :social_links, :json
  end
end
