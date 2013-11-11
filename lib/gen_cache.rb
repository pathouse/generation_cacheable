require 'uri'
require 'cityhash'
require "gen_cache/caches"
require "gen_cache/keys"
require "gen_cache/expiry"
require "gen_cache/cache_io/fetching"
require "gen_cache/cache_io/formatting"
require "gen_cache/cache_io/parsing"

module GenCache

  def self.included(base)
    base.extend(GenCache::Caches)
    base.extend(GenCache::ClassMethods)

    base.class_eval do
      class_attribute   :cached_key,
                        :cached_indices,
                        :cached_methods,
                        :cached_class_methods,
                        :cached_associations
      after_commit :expire_all
    end
  end

  module ClassMethods
    def model_cache(&block)
      instance_exec &block
    end
  end

end