class WorkSettingsController < ApplicationController
  before_action :authenticate_user! # 💡 必ず最初にログインを要求

  # 画面表示前に必ず初期データ（7日分）の存在を確認する
  before_action :ensure_default_settings, only: [ :index ]

  def index
    # ❌ 修正前: @work_settings = WorkSetting.all.order(:day_of_week)
    # ⭕ 修正後: 今の管理者の勤務時間設定だけを取得する
    @work_settings = current_user.work_settings.order(:day_of_week)
  end

  def edit
    # ⭕ 修正後: URL直接入力で他人の設定をいじられないようにガード
    @work_setting = current_user.work_settings.find(params[:id])
  end

  def update
    # ⭕ 修正後: 自分の設定のみを特定して更新
    @work_setting = current_user.work_settings.find(params[:id])
    if @work_setting.update(work_setting_params)
      redirect_to work_settings_path, notice: "勤務時間を更新しました"
    else
      render :edit, status: :unprocessable_entity # 💡 Rails 7以降でエラー表示を安定させるために status を追加
    end
  end

  private

  # 7日分のデータが不足している場合に自動作成するメソッド
  def ensure_default_settings
    (0..6).each do |day|
      # ❌ 修正前: WorkSetting.find_or_create_by!(...)
      # ⭕ 修正後: current_user.work_settings を起点にすることで、
      # まだ設定がない曜日のデータが作られるときに自動で user_id がセットされます！
      current_user.work_settings.find_or_create_by!(day_of_week: day) do |ws|
        ws.open_time ||= "09:00"
        ws.close_time ||= "18:00"
        ws.is_closed = false if ws.is_closed.nil?
        ws.is_holiday_open = false if ws.is_holiday_open.nil? # 💡 念のため祝日設定の初期値も明記
      end
    end
  end

  def work_setting_params
    params.require(:work_setting).permit(:open_time, :close_time, :is_closed, :is_holiday_open)
  end
end
