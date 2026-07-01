class WorkSettingsController < ApplicationController
  # 画面表示前に必ず初期データ（7日分）の存在を確認する
  before_action :ensure_default_settings, only: [:index]

  def index
    @work_settings = WorkSetting.all.order(:day_of_week)
  end

  def edit
    @work_setting = WorkSetting.find(params[:id])
  end

  def update
    @work_setting = WorkSetting.find(params[:id])
    if @work_setting.update(work_setting_params)
      redirect_to work_settings_path, notice: '勤務時間を更新しました'
    else
      render :edit
    end
  end

  private

  # 7日分のデータが不足している場合に自動作成するメソッド
  def ensure_default_settings
    (0..6).each do |day|
      WorkSetting.find_or_create_by!(day_of_week: day) do |ws|
        # 必要であればここで初期値（9:00-18:00など）を設定してください
        ws.open_time ||= "09:00"
        ws.close_time ||= "18:00"
        ws.is_closed = false if ws.is_closed.nil?
      end
    end
  end

  def work_setting_params
    params.require(:work_setting).permit(:open_time, :close_time, :is_closed,:is_holiday_open)
  end
end