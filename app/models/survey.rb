class Survey < ActiveRecord::Base
	belongs_to :user
	belongs_to :organization
	has_many :questions
end
