class Question < ActiveRecord::Base
	has_and_belongs_to_many :users
	belongs_to :suggestion
	belongs_to :survey
	has_many :questions_users
	has_many :options
end
