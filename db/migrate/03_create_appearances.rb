class CreateAppearances < ActiveRecord::Migration[5.0]
  def change
    create_table :appearances do |t|
      t.integer :event_id
      t.integer :artist_id
    end
  end
end
