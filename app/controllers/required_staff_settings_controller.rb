class RequiredStaffSettingsController < ApplicationController
  before_action :authenticate_user! # 💡 必ず最初にログインを要求

  def index
    RequiredStaffSetting.connection.clear_query_cache
    
    # 💡 修正：ログインしている管理者の設定だけを取得してソート
    all_settings = current_user.required_staff_settings.order(:start_time).to_a
    @required_staff_settings = all_settings.group_by(&:day_of_week)
    
    # 💡 修正：自分に紐づく新しいインスタンスを作成
    @new_setting = current_user.required_staff_settings.new
    @new_rule = ShiftRule.new
    
    @increase_data = {}
    @decrease_data = {}
    @diff_data = {}
    @working_hours = {}

    (0..6).each do |wday|
      # 💡 💡 注意ポイント 💡 💡
      # モデル内のクラスメソッド（get_increase_points_with_idsなど）に、
      # 自分のデータだけを計算できるように「current_user」を引数で渡します。
      # （※モデル側の修正内容は後述します）
      increases = RequiredStaffSetting.get_increase_points_with_ids(wday, current_user) || []
      decreases = RequiredStaffSetting.get_decrease_points(wday, current_user) || []
      
      @increase_data[wday] = increases
      @decrease_data[wday] = decreases
      @diff_data[wday] = {}
      
      daily_settings = @required_staff_settings[wday] || []
      
      increases.each_with_index do |inc, i|
        dec = decreases[i]
        next if inc[:time].nil?
        
        current_required = daily_settings.select do |s| 
          next unless s.start_time && s.end_time
          s.start_time.strftime("%H:%M") <= inc[:time] && s.end_time.strftime("%H:%M") > inc[:time]
        end.sum { |s| s.required_count || 0 }

        prev_count = daily_settings.select do |s|
          next unless s.end_time
          s.end_time.strftime("%H:%M") <= inc[:time]
        end.sum { |s| s.required_count || 0 }
        
        @diff_data[wday][inc[:time]] = current_required - prev_count
        
        if dec.present? && dec[:time].present?
          start_t = Time.parse(inc[:time])
          end_t = Time.parse(dec[:time])
          total_minutes = ((end_t - start_t) / 60).to_i
          
          break_time = total_minutes >= 480 ? 60 : (total_minutes > 360 ? 45 : 0)
          @working_hours["#{wday}_#{i}"] = total_minutes - break_time
        end
      end
    end
  end

  def edit
    # 💡 修正：他の管理者の設定をURL直接入力で盗み見られないように制限
    @required_staff_setting = current_user.required_staff_settings.find(params[:id])
  end

  def update
    # 💡 修正：自分の管理下にある設定だけを特定
    @setting = current_user.required_staff_settings.find(params[:id])
    if @setting.update(setting_params)
      redirect_to required_staff_settings_path, notice: '更新しました'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def create
    # 💡 修正：ログインしている管理者に自動で紐づけて作成（user_idが自動セットされます）
    @setting = current_user.required_staff_settings.build(setting_params)
    if @setting.save
      redirect_to required_staff_settings_path, notice: '設定を追加しました'
    else
      flash[:alert] = "設定の追加に失敗しました: #{@setting.errors.full_messages.join(', ')}"
      redirect_to required_staff_settings_path
    end
  end

  def generate_all
    # 💡 修正：シフト生成ロジック（クラスメソッド）にも「誰のシフトを生成するか」として current_user を渡します
    (0..6).each { |wday| RequiredStaffSetting.generate_rules_from_settings(wday, current_user) }
    redirect_to required_staff_settings_path, status: :see_other, notice: '全曜日のシフト枠を更新しました'
  end

  def destroy
    # 💡 修正：自分の管理下にある設定だけを特定して削除
    @setting = current_user.required_staff_settings.find(params[:id])
    @setting.destroy
    redirect_to required_staff_settings_path, status: :see_other, notice: '設定を削除しました'
  end

  private

  def setting_params
    # 💡 user_id は build 時に自動セットされるため、ここに :user_id を追記する必要はありません
    params.require(:required_staff_setting).permit(
      :day_of_week, 
      :start_time, 
      :end_time, 
      :required_count, 
      :job_type
    )
  end
end