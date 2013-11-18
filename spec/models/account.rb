class Account < ActiveRecord::Base
	include GenCache 
	
  belongs_to :user

  belongs_to :group
end
