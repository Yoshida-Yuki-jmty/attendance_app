# == Schema Information
#
# Table name: users
#
#  id              :bigint           not null, primary key
#  email           :string
#  name            :string
#  password_digest :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email  (email) UNIQUE
#
class User < ApplicationRecord
  has_secure_password
  has_many :attendances, dependent: :destroy
  has_many :breaktimes, through: :attendances

  before_save { self.email = email.downcase.strip }

  validates :name,  presence: true
  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: /\A[^@\s]+@[^@\s]+\z/ }
  validates :password, length: { minimum: 8 }, allow_nil: true
end
