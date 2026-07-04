require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # ヘッドレスChromeを指定し、Docker環境に必要なフラグを追加します
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400] do |driver_options|
    driver_options.add_argument('--no-sandbox')
    driver_options.add_argument('--disable-dev-shm-usage')
    driver_options.add_argument('--headless=new')
  end
end