class ShiftRequest < ApplicationRecord
  belongs_to :staff
  
  # 休み種別 (request_type)
  enum request_type: { public_holiday: 0, paid_holiday: 1 }
  
  # 承認状態 (status)
  enum status: { pending: 0, approved: 1, rejected: 2 }
  
  validates :request_date, presence: true, uniqueness: { scope: :staff_id }

  def request_type_label
    I18n.t("enums.shift_request.request_type.#{request_type}")
  end

  def status_label
    I18n.t("enums.shift_request.status.#{status}")
  end
  
end