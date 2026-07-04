class ChangeStatusInShiftRequests < ActiveRecord::Migration[7.0]
  def change
    # 既存のstatusをrequest_typeに改名
    rename_column :shift_requests, :status, :request_type
    # 新しく承認状態管理用のstatusを追加（デフォルトを申請中:0にする）
    add_column :shift_requests, :status, :integer, default: 0, null: false
  end
end
