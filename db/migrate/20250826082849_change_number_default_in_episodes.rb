class ChangeNumberDefaultInEpisodes < ActiveRecord::Migration[8.0]
  def change
    # Remove default value and allow null for number field
    change_column_default :episodes, :number, from: 999, to: nil
    change_column_null :episodes, :number, true
  end
end
