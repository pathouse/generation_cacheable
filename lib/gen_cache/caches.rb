require "gen_cache/cache_types/key_cache"
require "gen_cache/cache_types/attribute_cache"
require "gen_cache/cache_types/method_cache"
require "gen_cache/cache_types/class_method_cache"
require "gen_cache/cache_types/association_cache"

module GenCache
  module Caches
    include GenCache::KeyCache
    include GenCache::AttributeCache
    include GenCache::MethodCache
    include GenCache::ClassMethodCache
    include GenCache::AssocationCache
  end
end