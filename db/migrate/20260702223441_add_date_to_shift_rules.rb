class AddDateToShiftRules < ActiveRecord::Migration[7.2]
  def change
    add_column :shift_rules, :date, :date
  end
end
