class ShiftRequestsController < ApplicationController
  def index
    # 全スタッフの希望休を日付順で取得
    @shift_requests = ShiftRequest.includes(:staff).order(request_date: :asc)
  end

  def new
    @shift_request = ShiftRequest.new
  end

  def edit
    @shift_request = ShiftRequest.find(params[:id])
  end

  def update
    @shift_request = ShiftRequest.find(params[:id])
    if @shift_request.update(shift_request_params)
      redirect_to shift_requests_path, notice: '更新しました'
    else
      render :edit
    end
  end

  def create
    @shift_request = ShiftRequest.new(shift_request_params)
    # 現在ログインしているスタッフのIDを割り当てる想定（Devise等を利用している場合）
    # @shift_request.staff = current_staff 
    
    if @shift_request.save
      redirect_to shift_requests_path, notice: '希望休を申請しました。'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @shift_request = ShiftRequest.find(params[:id])
    @shift_request.destroy
    redirect_to shift_requests_path, notice: '申請を取り消しました。'
  end

  def shift_request_params
    params.require(:shift_request).permit(:staff_id, :request_date, :request_type, :status)
  end

  private

  def shift_request_params
    params.require(:shift_request).permit(:staff_id, :request_date, :request_type, :status)
  end
end