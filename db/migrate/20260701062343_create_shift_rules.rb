class CreateShiftRules < ActiveRecord::Migration[7.2]
  def change
    create_table :shift_rules do |t|
      t.integer :day_of_week
      t.time :start_time
      t.time :end_time
      t.integer :staff_count

      t.timestamps
    end
  end
end
