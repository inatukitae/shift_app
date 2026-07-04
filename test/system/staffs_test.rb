# test/system/staffs_test.rb
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
    click_on "新規スタッフ登録"

    fill_in "名前", with: "新しいスタッフ名"
    # job_typeのセレクトボックスや入力欄に合わせて調整してください
    click_on "登録する" # または "保存する" など、フォームのボタン名に合わせる

    assert_text "スタッフが登録されました"
  end

  test "should update Staff" do
    visit staffs_url
    click_on "詳細を表示", match: :first
    click_on "編集する" # 詳細画面(show.html.erb)に「編集する」リンクがある場合

    fill_in "名前", with: "更新された名前"
    click_on "更新する" # フォームのボタン名に合わせる

    assert_text "スタッフ情報が更新されました"
  end

  test "should destroy Staff" do
    visit staffs_url
    click_on "詳細を表示", match: :first

    # 詳細画面、または一覧画面に「削除」ボタンがある場合
    # ブラウザの確認ダイアログが出る場合は accept_confirm を使います
    page.accept_confirm do
      click_on "削除する"
    end

    assert_text "スタッフを削除しました"
  end
end
