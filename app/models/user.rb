class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :staffs, dependent: :destroy
  has_many :required_staff_settings, dependent: :destroy
  has_many :work_settings, dependent: :destroy
end