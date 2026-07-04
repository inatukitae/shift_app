require "test_helper"

class WorkSettingsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :work_settings, :users

  setup do
    @user = users(:one)
    sign_in @user
    
    # @user に紐づくレコードがなければ作成する
    @work_setting = @user.work_settings.first || @user.work_settings.create!(day_of_week: 0)
  end

  test "should get edit" do
    # これで確実にそのユーザーが所有するレコードに対してリクエストを送れる
    get edit_work_setting_url(@work_setting)
    assert_response :success
  end

  test "should update work setting" do
    patch work_setting_path(@work_setting), params: { work_setting: { is_closed: true } }
    assert_redirected_to work_settings_path # コントローラーの redirect_to に合わせる
  end
end
