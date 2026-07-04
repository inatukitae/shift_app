class ShiftRequest < ApplicationRecord
  belongs_to :staff

  # 修正：enumをハッシュ形式で明示的に定義
  enum :request_type, { public_holiday: 0, paid_holiday: 1 }, prefix: true
  enum :status, { pending: 0, approved: 1, rejected: 2 }, prefix: true

  validates :request_date, presence: true, uniqueness: { scope: :staff_id }

  def request_type_label
    I18n.t("enums.shift_request.request_type.#{request_type}")
  end

  def status_label
    I18n.t("enums.shift_request.status.#{status}")
  end
end
