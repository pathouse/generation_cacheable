class Account < ActiveRecord::Base
	include Cacheable 
	
  belongs_to :user

  belongs_to :group
end
