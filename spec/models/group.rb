class Group < ActiveRecord::Base
	include GenCache

  has_many :accounts

  has_many :images, as: :viewable
end
