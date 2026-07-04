require "test_helper"

class WorkSettingsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :work_settings, :users # これを追加

  setup do
    @user = users(:one)
    @work_setting = work_settings(:one) # ここで値が nil になっていないか確認が必要
    sign_in @user
  end

  test "should get index" do
    get work_settings_path
    assert_response :success
  end

  test "should get edit" do
    get edit_work_setting_path(@work_setting)
    assert_response :success
  end

  test "should update work setting" do
    patch work_setting_path(@work_setting), params: { work_setting: { is_closed: true } }
    assert_redirected_to work_setting_path(@work_setting)
  end
end