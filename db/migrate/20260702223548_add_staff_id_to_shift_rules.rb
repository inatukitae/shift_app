class AddStaffIdToShiftRules < ActiveRecord::Migration[7.2]
  def change
    add_column :shift_rules, :staff_id, :integer
  end
end
