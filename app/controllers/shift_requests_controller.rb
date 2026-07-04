class ShiftRequestsController < ApplicationController
  before_action :authenticate_user! # 💡 必ず最初にログインを要求

  def index
    # ❌ 修正前: @shift_requests = ShiftRequest.includes(:staff)...
    # ⭕ 修正後: 自分が登録したスタッフ (current_user.staffs) のIDだけを抽出し、その希望休に絞り込む
    staff_ids = current_user.staffs.pluck(:id)
    @shift_requests = ShiftRequest.where(staff_id: staff_ids).includes(:staff).order(request_date: :asc)
  end

  def new
    @shift_request = ShiftRequest.new
  end

  def edit
    # ⭕ 修正後: URLに他人の希望休のIDを直接入力して盗み見・編集されるのを防ぐガードを追加
    staff_ids = current_user.staffs.pluck(:id)
    @shift_request = ShiftRequest.where(staff_id: staff_ids).find(params[:id])
  end

  def update
    # ⭕ 修正後: 自分の管理下のスタッフの希望休だけを特定して更新
    staff_ids = current_user.staffs.pluck(:id)
    @shift_request = ShiftRequest.where(staff_id: staff_ids).find(params[:id])

    if @shift_request.update(shift_request_params)
      redirect_to shift_requests_path, notice: "更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def create
    # 💡 データの安全性のために、paramsで送られてきた staff_id が
    # 本当にこの管理者の登録したスタッフかどうかを検証して作成します
    @shift_request = ShiftRequest.new(shift_request_params)

    # 送られてきたスタッフが自分の管理下でない場合はエラーにするガード
    unless current_user.staffs.exists?(id: @shift_request.staff_id)
      redirect_to shift_requests_path, alert: "不正なスタッフが選択されました" and return
    end

    if @shift_request.save
      redirect_to shift_requests_path, notice: "希望休を申請しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    # ⭕ 修正後: 自分の管理下のスタッフの希望休だけを削除できるように制限
    staff_ids = current_user.staffs.pluck(:id)
    @shift_request = ShiftRequest.where(staff_id: staff_ids).find(params[:id])
    @shift_request.destroy
    redirect_to shift_requests_path, notice: "申請を取り消しました。"
  end

  private # 💡 private の位置を一番下に正しく修正（元コードはメソッドの下にありました）

  def shift_request_params
    params.require(:shift_request).permit(:staff_id, :request_date, :request_type, :status)
  end
end
