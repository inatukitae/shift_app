class RequiredStaffSettingsController < ApplicationController
  def index
    RequiredStaffSetting.connection.clear_query_cache
    all_settings = RequiredStaffSetting.order(:start_time).to_a
    @settings = all_settings.group_by(&:day_of_week)
    
    @new_setting = RequiredStaffSetting.new
    @new_rule = ShiftRule.new
    
    @increase_data = {}
    @decrease_data = {}
    @diff_data = {}
    @working_hours = {}

    (0..6).each do |wday|
      # 1. データを取得（モデル側で整理済み）
      increases = RequiredStaffSetting.get_increase_points_with_ids(wday)
      decreases = RequiredStaffSetting.get_decrease_points(wday)
      
      @increase_data[wday] = increases
      @decrease_data[wday] = decreases
      @diff_data[wday] = {}
      
      daily_settings = @settings[wday] || []
      
      # 2. インデックス順にペアリングして計算
      # increasesとdecreasesの要素数が一致している前提で添字iを使用
      increases.each_with_index do |inc, i|
        dec = decreases[i]
        
        # 差分の計算（開始時間に基づき算出）
        current_required = daily_settings.select do |s| 
          s.start_time.strftime("%H:%M") <= inc[:time] && s.end_time.strftime("%H:%M") > inc[:time]
        end.sum(&:required_count)

        prev_count = daily_settings.select{|s| s.end_time.strftime("%H:%M") <= inc[:time]}.sum(&:required_count)
        @diff_data[wday][inc[:time]] = current_required - prev_count
        
        # 3. 勤務時間の計算（デタラメな検索をせず、ペアのデカを使う）
        if dec.present?
          start_t = Time.parse(inc[:time])
          end_t = Time.parse(dec[:time])
          total_minutes = ((end_t - start_t) / 60).to_i
          
          # 休憩時間ルール
          break_time = total_minutes >= 480 ? 60 : (total_minutes > 360 ? 45 : 0)
          
          # ビュー側で参照するためにインデックスをキーにすると確実です
          @working_hours["#{wday}_#{i}"] = total_minutes - break_time
        end
      end
    end
  end

  def edit
    @required_staff_setting = RequiredStaffSetting.find(params[:id])
  end

  def update
    @setting = RequiredStaffSetting.find(params[:id])
    if @setting.update(setting_params)
      redirect_to required_staff_settings_path, notice: '更新しました'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def create
    @setting = RequiredStaffSetting.new(setting_params)
    if @setting.save
      redirect_to required_staff_settings_path, notice: '設定を追加しました'
    else
      flash[:alert] = "設定の追加に失敗しました: #{@setting.errors.full_messages.join(', ')}"
      redirect_to required_staff_settings_path
    end
  end

  def generate_all
    (0..6).each { |wday| RequiredStaffSetting.generate_rules_from_settings(wday) }
    redirect_to required_staff_settings_path, status: :see_other, notice: '全曜日のシフト枠を更新しました'
  end

  def destroy
    @setting = RequiredStaffSetting.find(params[:id])
    @setting.destroy
    redirect_to required_staff_settings_path, status: :see_other, notice: '設定を削除しました'
  end

  private

  def setting_params
    params.require(:required_staff_setting).permit(:day_of_week, :start_time, :end_time, :required_count)
  end
end