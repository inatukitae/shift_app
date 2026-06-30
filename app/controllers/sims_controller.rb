class SimsController < ApplicationController
  def index
  end

def new
    @start_date = Date.new(2026, 6, 11) # 例：固定の場合
    @end_date = @start_date.next_month.prev_day
    @calendar_days = (@start_date.beginning_of_week(:sunday)..@end_date.end_of_week(:sunday)).to_a
    @staffs = Staff.all # スタッフを取得

    # カレンダーの各週でスタッフを配布する準備
    @staff_assignments = {} 

    @calendar_days.each_slice(7) do |week|
      # 1. その週の有効な日付セル（11日以降かつ範囲内）を抽出
      valid_dates = week.select { |d| d >= @start_date && d <= @end_date }
      next if valid_dates.empty?

      # 2. セルをシャッフル（配置のランダム化）
      shuffled_dates = valid_dates.shuffle

      # 3. スタッフリストをシャッフル
      staff_pool = @staffs.to_a.shuffle

      # 4. スタッフを有効なセルに循環分配
      staff_pool.each_with_index do |staff, i|
        target_date = shuffled_dates[i % shuffled_dates.size]
        @staff_assignments[target_date] ||= []
        @staff_assignments[target_date] << staff
      end
    end
  end
end