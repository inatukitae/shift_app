class RequiredStaffSetting < ApplicationRecord
  belongs_to :user, optional: true

  # --- ヘルパーメソッド：時間を強制的に2000-01-01基準にする ---
  def self.to_base_time(time_val)
    time = if time_val.is_a?(String)
             Time.zone.parse("2000-01-01 #{time_val}")
    else
             time_val
    end
    time.change(year: 2000, month: 1, day: 1)
  end

  # --- 休憩時間計算 ---
  def self.calculate_working_minutes(start_time_str, end_time_str)
    start_t = to_base_time(start_time_str)
    end_t   = to_base_time(end_time_str)
    ((end_t - start_t) / 60).to_i
  end

  # --- その他のメソッドも to_base_time を活用 ---
  def self.required_count_at_in_memory(settings, time_str)
    time = to_base_time(time_str)
    setting = settings.find { |s| to_base_time(s.start_time) <= time && to_base_time(s.end_time) > time }
    setting&.required_count || 0
  end

  # 💡 修正：引数に user を追加し、そのユーザーのデータに絞り込み
  def self.get_increase_points_with_ids(wday, user)
    # ❌ 変更前: settings = where(day_of_week: wday)...
    # ⭕ 変更後: ログインユーザーに紐づく設定だけを対象にする
    settings = user.required_staff_settings.where(day_of_week: wday).order(:start_time).to_a
    return [] if settings.empty?

    results = []

    settings.each do |s|
      s_start = to_base_time(s.start_time)
      prev_time = s_start - 1.minute
      prev_setting = settings.find do |p|
        to_base_time(p.start_time) <= prev_time && to_base_time(p.end_time) > prev_time
      end

      prev_count = prev_setting&.required_count || 0

      if s.required_count > prev_count
        results << { id: s.id, time: s_start.strftime("%H:%M") }
      end
    end

    results
  end

  # 💡 修正：引数に user を追加し、重複していた定義を1つに統合
  def self.get_decrease_points(wday, user)
    # ⭕ ログインユーザーに紐づく設定だけを対象にする
    settings = user.required_staff_settings.where(day_of_week: wday).order(:end_time).to_a
    return [] if settings.empty?

    settings.map do |s|
      s_end = to_base_time(s.end_time)
      next_time = s_end + 1.minute

      next_count = settings.find do |n|
        to_base_time(n.start_time) <= next_time && to_base_time(n.end_time) > next_time
      end&.required_count || 0

      next_count < s.required_count ? { time: s_end.strftime("%H:%M") } : nil
    end.compact
  end

  # 💡 修正：引数に user を追加
  def self.get_count_diff_for_shift(wday, start_time_str, user)
    # ⭕ ログインユーザーに紐づく設定だけを対象にする
    settings = user.required_staff_settings.where(day_of_week: wday).to_a
    current_start = to_base_time(start_time_str)
    current_setting = settings.find { |s| to_base_time(s.start_time) == current_start }
    return 0 unless current_setting

    prev_time = current_start - 1.minute
    prev_count = settings.find { |s| to_base_time(s.start_time) <= prev_time && to_base_time(s.end_time) > prev_time }&.required_count || 0
    current_setting.required_count - prev_count
  end

  def to_base_time(time)
    return nil if time.nil?
    time.change(year: 2000, month: 1, day: 1)
  end
end
