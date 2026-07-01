class AddHolidaySettingsToWorkSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :work_settings, :is_holiday_open, :boolean
  end
end
