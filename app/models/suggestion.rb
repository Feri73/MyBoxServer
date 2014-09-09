class Suggestion < ActiveRecord::Base
	belongs_to :user
	belongs_to :organization
	has_one :question
end
