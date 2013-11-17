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
    with_method :meaning_of_life         # => user_instance.cached_meaning_of_life
    with_class_method :population        # => User.cached_population
    with_association :profile, :friends  # => user_instance.cached_profile  User.cached_friends
  end

  def self.population
    all.count
  end

  def meaning_of_life
    42
  end
end
```

IMPORTANT:

When caching associations, GenCache must be included in all of the models involved.


Why Another Caching Implementation?:
========

As stated above, this gem began as a fork of simple_cacheable. The intention was to solve marshalling errors (hence the object encoding and decoding borrowed from identity cache).

While working with simple cacheable I became very disastisifed with how association caching was handled. Generation Cacheable was written this principle in mind: 

#### Cache Implementations Shouldn't Think About Rails Associations

In a fetch operation, the cache is read, the value is found, or a block is executed to find that value and then it's written to the cache. That's it. Caching should neither know nor car where that value is coming from and what its relation is to the model executing the fetch request.
In a similar vein, when a model goes to expire its cache, it should do only that and not have to worry about expiring its associations. 

So association caches work like this:

```ruby
user_instance.cached_posts
```

When this method is called, this instance's posts cache is read, but instead of containing that users posts, it contains all of the cache keys for the posts in that association which are then retrieved in a multi_read.
So the trade off is - expiry is vastly simplified among complex associations, but reading associations from the cache hits memcached at least twice. 
