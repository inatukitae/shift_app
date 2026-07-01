class CreateShiftRequests < ActiveRecord::Migration[7.2]
  def change
    create_table :shift_requests do |t|
      t.references :staff, null: false, foreign_key: true
      t.date :request_date
      t.integer :status

      t.timestamps
    end
  end
end
