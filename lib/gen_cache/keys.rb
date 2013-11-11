module GenCache

  # Keys generated in hashes called Key blobs => { type: :key_type, key: 'key' }
  # The type is used by the fetcher so it doesn't have to parse
  # the key to figure out what kind it is and how to handle its contents.

  ## CLASS KEYS      

  # HASH generated from SCHEMA to indicate MODEL GENERATIONS
  # => "users/5821759535148822589"
  def self.model_prefix(klass)
    columns = klass.try(:columns)
    return if columns.nil?
    schema_string = columns.sort_by(&:name).map{|c| "#{c.name}:#{c.type}"}.join(',')
    generation = CityHash.hash64(schema_string)
    [klass.name.tableize, generation].join("/")
  end

  # => "users/5821759535148822589/64"
  def self.instance_key(klass, id)
    {type: :object,
     key: [model_prefix(klass), id].join("/") }
  end

  # => "users/5821759535148822589/attribute/value"
  # => "users/5821759535148822589/all/attribute/value"
  def self.attribute_key(klass, attribute, args, options={})
    att_args = [attribute, symbolize_args([args])].join("/")
    unless options[:all]
      { type: :object,
        key: [model_prefix(klass), att_args].join("/") }
    else
      { type: :object,
        key: [model_prefix(klass), "all", att_args].join("/") }
    end
  end

  # => "users/5821759535148822589/method"
  def self.class_method_key(klass, method)
    { type: :method, 
      key: [model_prefix(klass), method].join("/") }
  end

  def self.all_class_method_keys(klass)
    klass.cached_class_methods.map { |c_method| class_method_key(klass, c_method) }
  end

  ## INSTANCE KEYS

  # HASH generated from ATTRIBUTES to indicate INSTANCE GENERATIONS
  # => "users/5821759535148822589/64/12126514016877773284"
  def self.instance_prefix(instance)
    atts = instance.attributes
    att_string = atts.sort.map { |k, v| [k,v].join(":") }.join(",")
    generation = CityHash.hash64(att_string)
    [model_prefix(instance.class), instance.id, generation].join("/")
  end
 
  # => "users/5821759535148822589/64/12126514016877773284/method"
  def self.method_key(instance, method)
    { type: :method,
      key: [instance_prefix(instance), method].join("/") }
  end

  # => "users/5821759535148822589/64/12126514016877773284/association"
  def self.association_key(instance, association)
    { type: :association,
      key: [instance_prefix(instance), association].join("/") }
  end 
end