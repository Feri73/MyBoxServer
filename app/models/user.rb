class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :organizations
  has_and_belongs_to_many :organization
  has_many :suggestions
  has_many :surveys
  has_and_belongs_to_many :questions
  has_many :questions_users
  has_many :token
  has_many :requests

  after_initialize :init

    def init
      reputation ||= 0
    end
end
