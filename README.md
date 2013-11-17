Generation Cacheable
====================

A rails cache implementation that began as a fork of [simple cacheable](https://github.com/flyerhzm/simple_cacheable) and incorporated some ideas from [identity cache](https://github.com/Shopify/identity_cache) as well. 

Usage
=====

```ruby
class User < ActiveRecord::Base
  include GenCache

  has_one :profile
  has_many :friends

  model_cache do
    with_key                             # => User.find_cached(1)
    with_attribute :name                 # => User.find_cached_by_name("Pathouse")
    with_method :meaning_of_life         # => User.cached_meaning_of_life
    with_class_method :population        # => User.cached_population
    with_association :profile, :friends  # => User.cached_profile  User.cached_friends
  end

  def self.population
    all.count
  end

  def meaning_of_life
    42
  end
end
```

