class Organization < ActiveRecord::Base
	has_and_belongs_to_many :users
	belongs_to :user
	has_many :surveys
	has_many :suggestions
	has_many :requests
end
