module GenCache

  def expire_model_cache
    GenCache.expire(self)
  end

  # Manual expiry initiated by an object after commit
  # only has to worry about key_cache, attribute_cache, and class_method_cache
  def self.expire(object)
    expire_instance_key(object) if object.persisted?
    expire_class_method_keys(object)
    expire_attribute_keys(object)
  end

  def self.expire_instance_key(object)
    key = instance_key(object.class, object.id)
    Rails.cache.delete(key[:key])
  end

  def self.expire_class_method_keys(object)
    object.class.cached_class_methods.map do |class_method|
      key = class_method_key(object.class, class_method)
    end.each do |method_key|
      Rails.cache.delete(method_key[:key])
    end
  end

  # cached attributes are stored like:
  # { attribute => [value1, value2] }
  def self.expire_attribute_keys(object)
    object.class.cached_indices.map do |index, values|
      values.map { |v| attribute_key(object.class, index, v) }
    end.flatten.each do |attribute_key|
      Rails.cache.delete(attribute_key[:key])
    end
  end
end