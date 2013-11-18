module GenCache
  module AssocationCache

    def with_association(*association_names)
      self.cached_associations ||= []
      self.cached_associations += base_class.cached_associations
      self.cached_associations += association_names

      association_names.each do |assoc_name|
        cached_assoc_methods(assoc_name)
      end
    end

    def cached_assoc_methods(name)
      method_name = "cached_#{name}"
      define_method(method_name) do
        cache_key = GenCache.association_key(self, name)
        
        # an object's association cache holds a collection of the instance keys
        # for the objects returned by a call to that association. These are read first
        if instance_variable_get("@#{method_name}").nil?
          instance_keys = GenCache.fetch(cache_key) do
            Array.wrap(self.send(name)).map { |obj| GenCache.instance_key(obj.class, obj.id) }
          end
          
          # all of the instance keys are read in a single multi_read
          association = GenCache.fetch(instance_keys) do |key_blobs|
            result = {}
            instance_keys.each do |ik|
              key_parts = ik[:key].scan(/(^.*)\/(.*)\/(.*$)/).flatten
              result[ik] = Object.const_get(key_parts.first.singularize.capitalize).send(:find, key_parts.last.to_i)
            end
            result
          end

          # plural associations expect arrays, singular associations expect single objects
          association = if association.size == 0 
                          name.to_s.pluralize == name.to_s ? [] : nil
                        elsif association.size == 1
                          name.to_s.pluralize == name.to_s ? association : association.first
                        else
                          association
                        end

          instance_variable_set("@#{method_name}", association)
        end
        instance_variable_get("@#{method_name}")
      end
    end
  end
end