module GenCache
  module ClassMethodCache
    # Cached class method
    # Should expire on any instance save
    def with_class_method(*methods)
      self.cached_class_methods ||= []
      self.cached_class_methods += methods

      methods.each do |meth|
        define_singleton_method("cached_#{meth}") do |*args|
          cache_key = GenCache.class_method_key(self, meth)
          GenCache.fetch(cache_key, args: args) do
            unless args.empty?
              self.send(meth, *args)
            else
              self.send(meth)
            end
          end
        end
      end
    end
  end
end