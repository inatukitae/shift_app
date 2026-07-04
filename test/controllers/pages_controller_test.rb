require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get pages_home_url # routes.rb の定義を確認してください
    assert_response :success
  end
end
