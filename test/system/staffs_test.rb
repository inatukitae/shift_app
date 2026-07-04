require "application_system_test_case"

class StaffsTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  setup do
    @staff = staffs(:one)
    @user = users(:one)
    login_as @user
  end

  test "visiting the index" do
    visit staffs_url
    assert_selector "h1", text: "スタッフ一覧"
  end

  test "should create staff" do
    visit staffs_url
    click_on "新規スタッフ登録" # ビューのリンク名に変更

    fill_in "名前", with: @staff.name # ラベル名「名前」に変更
    select "薬剤師", from: "職種"    # セレクトボックス用に追加
    click_on "保存する"             # フォームのボタン名に変更

    assert_text "Staff was successfully created" # ここはコントローラーのメッセージに合わせてください
    click_on "スタッフ一覧に戻る"
  end

  test "should update Staff" do
    visit staff_url(@staff)
    click_on "編集する" # ビューのリンク名に変更

    fill_in "名前", with: @staff.name
    click_on "保存する" # フォームのボタン名に変更

    assert_text "Staff was successfully updated"
    click_on "スタッフ一覧に戻る"
  end

  test "should destroy Staff" do
    visit staff_url(@staff)
    click_on "削除する" # ビューのリンク名に変更

    assert_text "Staff was successfully destroyed"
  end
end