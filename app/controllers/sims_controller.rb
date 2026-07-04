class SimsController < ApplicationController
  before_action :authenticate_user! # 💡 ログインを必須にする
  require "holidays"

  def index
    # 💡 自分の管理下のスタッフのシフト（ShiftRule）だけを取得する
    staff_ids = current_user.staffs.pluck(:id)

    @past_shifts = ShiftRule.where(staff_id: staff_ids).order(date: :desc).group_by(&:date)

    @saved_periods = ShiftRule.where(staff_id: staff_ids).where.not(batch_id: nil)
                              .group_by(&:batch_id)
                              .map do |batch_id, shifts|
                                {
                                  batch_id: batch_id,
                                  start: shifts.map(&:date).min,
                                  end: shifts.map(&:date).max
                                }
                              end
                              .sort_by { |p| p[:start] }.reverse

    @saved_periods ||= []
  end

  def show
    @start_date = Date.parse(params[:start_date])
    @end_date = Date.parse(params[:end_date])
    @days = (@start_date..@end_date).to_a

    # 💡 Staff.all ではなく、自分のスタッフだけに限定
    @staffs = current_user.staffs
    @pharmacists = current_user.staffs.where(job_type: "薬剤師")
    @clerks = current_user.staffs.where(job_type: "事務員")

    @shift_map = {}

    # 💡 自分のスタッフのシフトだけを抽出
    staff_ids = @staffs.pluck(:id)
    ShiftRule.where(staff_id: staff_ids, date: @start_date..@end_date).each do |s|
      @shift_map[[ s.staff_id, s.date ]] = "#{s.start_time.strftime('%H:%M')}-#{s.end_time.strftime('%H:%M')}"
    end
  end

  def new
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.new(2026, 6, 11)
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : @start_date.next_month.prev_day
    @calendar_days = (@start_date.beginning_of_week(:sunday)..@end_date.end_of_week(:sunday)).to_a

    # 💡 自分のスタッフ、設定データだけに限定
    @staffs = current_user.staffs
    @pharmacists = current_user.staffs.where(job_type: "薬剤師")
    @clerks = current_user.staffs.where(job_type: "事務員")

    @work_settings_list = current_user.work_settings.order(:day_of_week)
    @work_settings_map = current_user.work_settings.index_by(&:day_of_week)

    # 💡 自分のスタッフの希望休だけに限定
    staff_ids = @staffs.pluck(:id)
    @shift_requests = ShiftRequest.where(staff_id: staff_ids).includes(:staff).order(request_date: :asc)
    @requests_by_date = @shift_requests.group_by(&:request_date)

    @frame_data = {}
    @frame_data["薬剤師"] = prepare_frame_data("薬剤師")
    @frame_data["事務員"] = prepare_frame_data("事務員")

    @pharmacist_results = generate_job_type_shifts(@pharmacists, @frame_data["薬剤師"])
    @clerk_results = generate_job_type_shifts(@clerks, @frame_data["事務員"])

    @pharmacist_assignments            = @pharmacist_results[:assignments]
    @pharmacist_work_days              = @pharmacist_results[:work_days]
    @pharmacist_total_working_minutes  = @pharmacist_results[:total_working_minutes]

    @clerk_assignments                 = @clerk_results[:assignments]
    @clerk_work_days                   = @clerk_results[:work_days]
    @clerk_total_working_minutes       = @clerk_results[:total_working_minutes]

    @staff_assignments = {}
    (@pharmacist_assignments.keys + @clerk_assignments.keys).uniq.each do |date|
      @staff_assignments[date] = (@pharmacist_assignments[date] || []) + (@clerk_assignments[date] || [])
    end
    @staff_work_days = @pharmacist_work_days.merge(@clerk_work_days)
    @staff_total_working_minutes = @pharmacist_total_working_minutes.merge(@clerk_total_working_minutes)
  end

  def save_shifts
    batch_id = Time.now.to_i.to_s

    # 💡 不正な staff_id が送られてこないよう、自分のスタッフのIDリストを取得
    valid_staff_ids = current_user.staffs.pluck(:id)

    params[:shifts].each do |date_str, staffs|
      date = Date.parse(date_str)
      staffs.each do |staff_id, times|
        # 💡 もし他人のスタッフIDが送られてきたらスキップする（セキュリティ対策）
        next unless valid_staff_ids.include?(staff_id.to_i)

        shift = ShiftRule.find_or_initialize_by(date: date, staff_id: staff_id)
        shift.attributes = {
          day_of_week: date.wday,
          start_time: times[:start],
          end_time: times[:end],
          staff_count: 1,
          batch_id: batch_id
        }
        shift.save
      end
    end

    redirect_to sims_path, notice: "シフトを1つのデータセットとして保存しました。"
  end

  def destroy_batch
    # 💡 自分のスタッフのシフトに限定して削除
    staff_ids = current_user.staffs.pluck(:id)
    ShiftRule.where(staff_id: staff_ids, batch_id: params[:batch_id]).destroy_all

    redirect_to sims_path, notice: "シフトセットを削除しました。"
  end

  def is_holiday_or_closed?(date, work_settings_map)
    setting = work_settings_map[date.wday]
    is_closed = setting&.is_closed
    is_holiday = Holidays.on(date, :jp).any?

    if is_holiday && !setting&.is_holiday_open
      return true
    end
    is_closed
  end

  def is_holiday?(date)
    Holidays.on(date, :jp).any?
  end

  def should_be_closed?(date, setting)
    return true if setting&.is_closed && !setting&.is_holiday_open
    return true if setting&.is_closed
    false
  end

  private

  def prepare_frame_data(job_type)
    increase_data = {}
    decrease_data = {}
    diff_data = {}
    working_hours = {}

    # 💡 ここも `RequiredStaffSetting.where` ではなく、自分の設定のみ取得する
    settings_for_job = current_user.required_staff_settings.where(job_type: job_type).order(:start_time).group_by(&:day_of_week)

    (0..6).each do |wday|
      daily_settings = settings_for_job[wday] || []

      times = daily_settings.map { |s| [ s.start_time.strftime("%H:%M"), s.end_time.strftime("%H:%M") ] }.flatten.uniq.sort

      increases = []
      decreases = []
      current_count = 0

      times.each do |t|
        count = daily_settings.select { |s| s.start_time.strftime("%H:%M") <= t && s.end_time.strftime("%H:%M") > t }.sum(&:required_count)

        if count > current_count
          (count - current_count).times { increases << { time: t } }
        elsif count < current_count
          (current_count - count).times { decreases << { time: t } }
        end
        current_count = count
      end

      increase_data[wday] = increases
      decrease_data[wday] = decreases
      diff_data[wday] = {}

      increases.each_with_index do |inc, i|
        dec = decreases[i]

        current_required = daily_settings.select { |s| s.start_time.strftime("%H:%M") <= inc[:time] && s.end_time.strftime("%H:%M") > inc[:time] }.sum(&:required_count)
        prev_count = daily_settings.select { |s| s.end_time.strftime("%H:%M") <= inc[:time] }.sum(&:required_count)

        diff_data[wday][inc[:time]] = current_required - prev_count

        if dec.present?
          start_t = Time.parse(inc[:time])
          end_t = Time.parse(dec[:time])
          total_minutes = ((end_t - start_t) / 60).to_i
          break_time = total_minutes >= 480 ? 60 : (total_minutes > 360 ? 45 : 0)
          working_hours["#{wday}_#{i}"] = total_minutes - break_time
        end
      end
    end

    { increase: increase_data, decrease: decrease_data, diff: diff_data, hours: working_hours }
  end

  # generate_job_type_shifts メソッドは、引数として受け取る target_staffs が
  # すでに current_user のスタッフに絞り込まれているため、そのままで安全に動きます！
  def generate_job_type_shifts(target_staffs, frame)
    staff_assignments = {}

    job_type_requests = ShiftRequest.where(staff_id: target_staffs.map(&:id)).includes(:staff)
    requests_by_date = job_type_requests.group_by(&:request_date)

    has_kokyu_in_week = {}
    job_type_requests.each do |req|
      if req.request_type_label == "公休"
        week_start = req.request_date.beginning_of_week(:sunday)
        has_kokyu_in_week[[ req.staff_id, week_start ]] = true
      end
    end

    @calendar_days.each_slice(7) do |week|
      week_start = week.first.beginning_of_week(:sunday)

      all_possible_dates = week.select do |d|
        setting = @work_settings_map[d.wday]
        !(setting&.is_closed)
      end

      next if all_possible_dates.empty?

      available_staffs = target_staffs.reject { |s| has_kokyu_in_week[[ s.id, week_start ]] }
      staff_pool = available_staffs.shuffle

      staff_pool.each do |staff|
        date_counts = all_possible_dates.map do |date|
          req_count = requests_by_date[date] ? requests_by_date[date].size : 0
          assign_count = staff_assignments[date] ? staff_assignments[date].size : 0
          { date: date, count: req_count + assign_count }
        end

        min_count = date_counts.map { |dc| dc[:count] }.min
        candidate_dates = date_counts.select { |dc| dc[:count] == min_count }.map { |dc| dc[:date] }
        target_date = candidate_dates.sample

        staff_assignments[target_date] ||= []
        staff_assignments[target_date] << staff
      end
    end

    staff_total_working_minutes = Hash.new(0)
    active_dates = @calendar_days.select { |d| d >= @start_date && d <= @end_date && !(@work_settings_map[d.wday]&.is_closed) }

    (@start_date..@end_date).each do |date|
      next if @work_settings_map[date.wday]&.is_closed

      assigned_holidays = staff_assignments[date.to_date] || []
      increases = frame[:increase][date.wday] || []
      decreases = frame[:decrease][date.wday] || []
      num_of_slots = [ increases.length, decreases.length ].max

      available = target_staffs.reject { |s| assigned_holidays.include?(s) || (requests_by_date[date.to_date] || []).map(&:staff_id).include?(s.id) }
      next if available.empty?

      current_index = active_dates.index(date) || 0
      rotated = available.rotate(current_index)

      (0...num_of_slots).each do |i|
        staff = if available.size == 1
                  (i == 1) ? rotated[0] : nil
        else
                  rotated[i]
        end

        if staff
          pair_key = "#{date.wday}_#{i}"
          staff_total_working_minutes[staff.id] += frame[:hours][pair_key] || 0
        end
      end
    end

    staff_work_days = {}
    target_staffs.each do |staff|
      count = 0
      (@start_date..@end_date).each do |date|
        next if @work_settings_map[date.wday]&.is_closed
        is_requested_off = (requests_by_date[date.to_date] || []).any? { |r| r.staff_id == staff.id }
        next if is_requested_off
        assigned_holidays = staff_assignments[date.to_date] || []
        is_assigned_holiday = assigned_holidays.include?(staff)
        next if is_assigned_holiday

        count += 1
      end
      staff_work_days[staff.id] = count
    end

    {
      assignments: staff_assignments,
      total_working_minutes: staff_total_working_minutes,
      work_days: staff_work_days
    }
  end
end
