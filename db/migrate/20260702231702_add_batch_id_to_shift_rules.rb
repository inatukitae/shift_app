class AddBatchIdToShiftRules < ActiveRecord::Migration[7.2]
  def change
    add_column :shift_rules, :batch_id, :string
  end
end
