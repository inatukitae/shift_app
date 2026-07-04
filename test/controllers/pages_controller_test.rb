require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers # 💡 これを追加

  setup do
    @user = users(:one) # fixtures :users が必要です
    sign_in @user        # 💡 これでログイン状態にする
  end

  test "should get index" do
    get root_url
    assert_response :success
  end
end