class CreateEvents < ActiveRecord::Migration[5.0]
  def change
    create_table :events do |t|
      t.string :name
      t.datetime :date 
      t.string :city
      t.string :state
      t.string :venue_name
    end
  end
end
