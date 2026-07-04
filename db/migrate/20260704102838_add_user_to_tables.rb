class AddUserToTables < ActiveRecord::Migration[7.2]
  def change
    # 第一引数に「追加先のテーブル名（複数形）」、第二引数に「user」を指定します
    add_reference :staffs, :user, null: true, foreign_key: true
    add_reference :required_staff_settings, :user, null: true, foreign_key: true
    add_reference :work_settings, :user, null: true, foreign_key: true
  end
end
