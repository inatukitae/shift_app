require "test_helper"

class WorkSettingsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get work_settings_index_url
    assert_response :success
  end

  test "should get edit" do
    get work_settings_edit_url
    assert_response :success
  end

  test "should get update" do
    get work_settings_update_url
    assert_response :success
  end
end
