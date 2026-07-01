class CreateRequiredStaffSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :required_staff_settings do |t|
      t.integer :day_of_week
      t.time :start_time
      t.time :end_time
      t.integer :required_count

      t.timestamps
    end
  end
end
