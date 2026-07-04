class Staff < ApplicationRecord
  # 💡 追記：このスタッフは特定の管理者（ユーザー）に属する
  # optional: true をつけておくことで、既存の（user_idが空の）データがあってもエラーになりません
  belongs_to :user, optional: true

  # 💡 追記：スタッフは複数のシフト希望を持つ
  # スタッフが削除されたら、その人のシフト希望も自動で消えるようにします
  has_many :shift_requests, dependent: :destroy
end