class CreateWorkSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :work_settings do |t|
      t.integer :day_of_week
      t.time :open_time
      t.time :close_time
      t.boolean :is_closed

      t.timestamps
    end
  end
end
