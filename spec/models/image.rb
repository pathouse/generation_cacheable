class Image < ActiveRecord::Base
	include GenCache

  belongs_to :viewable, :polymorphic => true

  after_commit :do_something

  def do_something
    e = 1337
  end
end
