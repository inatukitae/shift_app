class WorkSetting < ApplicationRecord
    belongs_to :user, optional: true
end
