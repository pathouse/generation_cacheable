module GenCache

	def self.parse_with_key(result, key_type)
		return if result.nil?
		if key_type == :association
			result
		elsif key_type == :object
			object_parse(result)
		else
			method_parse(result)
		end
	end

	## OBJECT PARSING ##

	def self.object_parse(result)
		if result.is_a?(Array)
			result.map {|obj| record_from_coder(obj)}
		else
			record_from_coder(result)
		end
	end

	def self.record_from_coder(coder)
		record = coder[:class].allocate
		record.init_with(coder)
		record
	end

	## METHOD PARSING ## 
	#
	## METHOD STORE FORMATTING
	#
	# { args.to_string.to_symbol => answer }

	def self.detect_coder(data)
		(data.is_a?(Hash) && hash_inspect(data)) ||
		(data.is_a?(Array) && data[0].is_a?(Hash) && hash_inspect(data[0]))
	end

	def self.hash_inspect(hash)
		hash.has_key?(:class) && hash.has_key?('attributes')
	end

	def self.method_parse(result)
		if detect_coder(result)
			object_parse(result)
		elsif result.is_a?(Hash)
			result.each do |k,v|
				result[k] = data_parse(v)
			end
		else
			data_parse(result)
		end
	end

	## DATA PARSING ##

	def self.data_parse(result)
		if detect_coder(result)
			object_parse(result)
		else
			result
		end
	end
end