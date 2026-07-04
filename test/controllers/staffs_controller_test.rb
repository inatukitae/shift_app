require "application_system_test_case"

class StaffsTest < ApplicationSystemTestCase
  setup do
    @staff = staffs(:one)
    # ログインが必要な場合はここに追記
    # sign_in users(:one)
  end

  test "visiting the index" do
    visit staffs_url
    assert_selector "h1", text: "スタッフ一覧"
  end

  test "should create staff" do
    visit staffs_url
    click_on "新規スタッフ登録"

    fill_in "名前", with: @staff.name
    select "薬剤師", from: "職種" # selectボックスの操作
    click_on "保存する" # フォーム内のボタン名に修正

    assert_text "Staff was successfully created"
    click_on "スタッフ一覧に戻る"
  end

  test "should update Staff" do
    visit staff_url(@staff)
    click_on "編集する"

    fill_in "名前", with: @staff.name
    click_on "保存する" # フォーム内のボタン名に修正

    assert_text "Staff was successfully updated"
    click_on "スタッフ一覧に戻る"
  end

  test "should destroy Staff" do
    visit staff_url(@staff)
    click_on "削除する"

    assert_text "Staff was successfully destroyed"
  end
end