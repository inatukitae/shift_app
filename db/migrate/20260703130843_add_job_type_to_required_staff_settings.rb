class AddJobTypeToRequiredStaffSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :required_staff_settings, :job_type, :string
  end
end
