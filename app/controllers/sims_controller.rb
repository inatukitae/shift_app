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
    @settings = RequiredStaffSetting.all.group_by(&:day_of_week)

    @staff_assignments = {} 

    # --- 修正箇所1: 希望休の取得を割り当てループの前に移動 ---
    @shift_requests = ShiftRequest.includes(:staff).order(request_date: :asc)
    @requests_by_date = @shift_requests.group_by(&:request_date)
    
    # 「公休」がある週のスタッフのみ除外するハッシュを作成
    has_kokyu_in_week = {}
    @shift_requests.each do |req|
      if req.request_type_label == "公休"
        week_start = req.request_date.beginning_of_week(:sunday)
        has_kokyu_in_week[[req.staff_id, week_start]] = true
      end
    end

    @calendar_days.each_slice(7) do |week|
      week_start = week.first.beginning_of_week(:sunday)
      
      # 1. すべての曜日を対象にして、定休日だけをフィルタリング
      all_possible_dates = week.select do |d| 
        setting = @work_settings_map[d.wday]
        !(setting&.is_closed)
      end
      
      next if all_possible_dates.empty?

      # 「公休」があるスタッフのみをその週のプールから除外
      available_staffs = @staffs.reject { |s| has_kokyu_in_week[[s.id, week_start]] }
      
      # ランダム性を担保するためスタッフをシャッフル
      staff_pool = available_staffs.shuffle

      # --- 修正箇所2: 休みが少ない日を優先して割り当てるロジック ---
      staff_pool.each do |staff|
        # a. 各営業日の現在の「休み人数（希望休 + アサイン済）」を算出
        date_counts = all_possible_dates.map do |date|
          req_count = @requests_by_date[date] ? @requests_by_date[date].size : 0
          assign_count = @staff_assignments[date] ? @staff_assignments[date].size : 0
          { date: date, count: req_count + assign_count }
        end
        
        # b. 休み人数の最小値を取得（誰も休んでいない日があれば0になる）
        min_count = date_counts.map { |dc| dc[:count] }.min
        
        # c. 最小値と一致する日（候補日）だけを抽出
        candidate_dates = date_counts.select { |dc| dc[:count] == min_count }.map { |dc| dc[:date] }
        
        # d. 候補の中からランダムに1日を選び、割り当てを確定
        target_date = candidate_dates.sample
        
        @staff_assignments[target_date] ||= []
        @staff_assignments[target_date] << staff
      end
    end
  
    # 以下の設定データ作成処理はそのまま
    @settings = RequiredStaffSetting.order(:start_time).group_by(&:day_of_week)
    @increase_data = {}
    @decrease_data = {}
    @diff_data = {}
    @working_hours = {}

    (0..6).each do |wday|
      increases = RequiredStaffSetting.get_increase_points_with_ids(wday)
      decreases = RequiredStaffSetting.get_decrease_points(wday)
      @increase_data[wday] = increases
      @decrease_data[wday] = decreases
      @diff_data[wday] = {}
      
      daily_settings = @settings[wday] || []
      
      increases.each_with_index do |inc, i|
        dec = decreases[i]
        
        current_required = daily_settings.select do |s| 
          s.start_time.strftime("%H:%M") <= inc[:time] && s.end_time.strftime("%H:%M") > inc[:time]
        end.sum(&:required_count)
        
        prev_count = daily_settings.select{|s| s.end_time.strftime("%H:%M") <= inc[:time]}.sum(&:required_count)
        @diff_data[wday][inc[:time]] = current_required - prev_count
        
        if dec.present?
          start_t = Time.parse(inc[:time])
          end_t = Time.parse(dec[:time])
          total_minutes = ((end_t - start_t) / 60).to_i
          break_time = total_minutes >= 480 ? 60 : (total_minutes > 360 ? 45 : 0)
          @working_hours["#{wday}_#{i}"] = total_minutes - break_time
        end
      end
    end

    @staff_work_days = {}
    @staff_total_working_minutes = Hash.new(0) # 各スタッフの合計勤務時間（分）を保持するハッシュ
    
    # ループ内で使うための「定休日ではない有効な営業日」のリスト
    active_dates = @calendar_days.select { |d| d >= @start_date && d <= @end_date && !(@work_settings_map[d.wday]&.is_closed) }

    # 1. 各日のシフト枠割り当てを再現し、該当する枠の勤務時間を集計
    (@start_date..@end_date).each do |date|
      # 定休日はスキップ
      next if @work_settings_map[date.wday]&.is_closed
      
      assigned_holidays = @staff_assignments[date.to_date] || []
      increases = @increase_data[date.wday] || []
      decreases = @decrease_data[date.wday] || []
      num_of_slots = [increases.length, decreases.length].max
      
      # 出勤可能なスタッフを取得（休みを除外）
      available = @staffs.reject { |s| assigned_holidays.include?(s) || (@requests_by_date[date.to_date] || []).map(&:staff_id).include?(s.id) }
      next if available.empty?
      
      current_index = active_dates.index(date) || 0
      rotated = available.rotate(current_index)
      
      (0...num_of_slots).each do |i|
        # シフト枠確認と全く同じ条件でスタッフを特定
        staff = if available.size == 1
                  (i == 1) ? rotated[0] : nil
                else
                  rotated[i]
                end
        
        if staff
          # 曜日(wday)と枠インデックス(i)をキーにして、設定された勤務時間(分)を加算
          pair_key = "#{date.wday}_#{i}"
          @staff_total_working_minutes[staff.id] += @working_hours[pair_key] || 0
        end
      end
    end

    # 2. 出勤日数のカウント（既存のロジックのまま）
    @staffs.each do |staff|
      count = 0
      
      (@start_date..@end_date).each do |date|
        next if @work_settings_map[date.wday]&.is_closed
        is_requested_off = (@requests_by_date[date.to_date] || []).any? { |r| r.staff_id == staff.id }
        next if is_requested_off
        assigned_holidays = @staff_assignments[date.to_date] || []
        is_assigned_holiday = assigned_holidays.include?(staff)
        next if is_assigned_holiday

        count += 1
      end
      
      @staff_work_days[staff.id] = count
    end

  end


  
end