class ShiftRule < ApplicationRecord
  belongs_to :staff
  # 曜日（0:日, 1:月...）, 開始時間, 終了時間, 人数が必須
  validates :day_of_week, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :staff_count, presence: true, numericality: { greater_than: 0 }

  def self.get_change_points(wday)
    settings = where(day_of_week: wday).order(:start_time)
    return [] if settings.empty?

    # 開始時間と終了時間をすべて集めて、重複を除き、時系列順に並べる
    points = (settings.pluck(:start_time) + settings.pluck(:end_time)).uniq.sort

    # 変化点のみを抽出
    change_points = []
    points.each do |time|
      # その時間になった時の必要人数を取得
      # （その時間に重なっている設定の中で最大の人数を採用）
      count = settings.where("start_time <= ? AND end_time > ?", time, time).maximum(:required_count) || 0
      change_points << { time: time, required_count: count }
    end
    change_points
  end
end
