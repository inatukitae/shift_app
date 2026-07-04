require "test_helper"

class StaffsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers # Deviseのテストヘルパーを有効化

  setup do
    @staff = staffs(:one)
    @user = users(:one) # フィクスチャからログイン用のユーザーを取得
    sign_in @user        # 各テストの前にログインさせる
  end

  test "should get index" do
    get staffs_url
    assert_response :success
  end

  test "should get new" do
    get new_staff_url
    assert_response :success
  end

  test "should create staff" do
    assert_difference("Staff.count") do
      post staffs_url, params: { staff: { name: @staff.name, job_type: @staff.job_type } }
    end

    assert_redirected_to staff_url(Staff.last)
  end

  test "should show staff" do
    get staff_url(@staff)
    assert_response :success
  end

  test "should get edit" do
    get edit_staff_url(@staff)
    assert_response :success
  end

  test "should update staff" do
    patch staff_url(@staff), params: { staff: { name: @staff.name } }
    assert_redirected_to staff_url(@staff)
  end

  test "should destroy staff" do
    assert_difference("Staff.count", -1) do
      delete staff_url(@staff)
    end

    assert_redirected_to staffs_url
  end
end