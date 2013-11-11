class Tag < ActiveRecord::Base
	include Cacheable

  has_and_belongs_to_many :posts

end