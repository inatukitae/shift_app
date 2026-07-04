class AddJobTypeToStaffs < ActiveRecord::Migration[7.2]
  def change
    add_column :staffs, :job_type, :string
  end
end
