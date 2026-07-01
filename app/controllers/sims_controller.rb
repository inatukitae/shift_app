class SimsController < ApplicationController
  def index
  end

  def new
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.new(2026, 6, 11)
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : @start_date.next_month.prev_day
    
    @calendar_days = (@start_date.beginning_of_week(:sunday)..@end_date.end_of_week(:sunday)).to_a
    @staffs = Staff.all
    
    # ビュー表示用とカレンダー判定用の両方を用意
    @work_settings_list = WorkSetting.order(:day_of_week)
    @work_settings_map = WorkSetting.all.index_by(&:day_of_week)

    @staff_assignments = {} 
    
    # 修正: 「公休」がある週のスタッフのみ除外するハッシュを作成
    has_kokyu_in_week = {}
    ShiftRequest.all.each do |req|
      # ラベル名は適宜調整してください（'公休'）
      if req.request_type_label == "公休"
        week_start = req.request_date.beginning_of_week(:sunday)
        has_kokyu_in_week[[req.staff_id, week_start]] = true
      end
    end

    @calendar_days.each_slice(7) do |week|
      week_start = week.first.beginning_of_week(:sunday)
      
      # 1. すべての曜日を対象にして、定休日だけをフィルタリング
      # 期間外（グレーアウト）も含めて、営業日ならすべて対象にする
      all_possible_dates = week.select do |d| 
        setting = @work_settings_map[d.wday]
        !(setting&.is_closed)
      end
      
      next if all_possible_dates.empty?

      # 2. 割り当ては「カレンダーに表示されているすべての営業日」に広げる
      # これにより、期間外のマスも割り当て対象になります
      valid_assignment_dates = all_possible_dates

      # 「公休」があるスタッフのみをその週のプールから除外
      available_staffs = @staffs.reject { |s| has_kokyu_in_week[[s.id, week_start]] }
      
      shuffled_dates = valid_assignment_dates.shuffle
      staff_pool = available_staffs.shuffle

      staff_pool.each_with_index do |staff, i|
        # まんべんなく割り当てるため、日付リストをループさせる
        target_date = shuffled_dates[i % shuffled_dates.size]
        @staff_assignments[target_date] ||= []
        @staff_assignments[target_date] << staff
      end
    end

    @shift_requests = ShiftRequest.includes(:staff).order(request_date: :asc)
    @requests_by_date = ShiftRequest.includes(:staff).order(request_date: :asc).group_by(&:request_date)
  end
end