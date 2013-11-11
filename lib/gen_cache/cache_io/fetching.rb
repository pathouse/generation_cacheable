module GenCache

	def self.fetch(key_blob, options={}, &block)
		unless key_blob.is_a?(Array)
			single_fetch(key_blob, options) { yield if block_given? }
		else
			multiple_fetch(key_blob) { yield if block_given? }
		end
	end

	def self.single_fetch(key_blob, options, &block)
		result = read_from_cache(key_blob)
		method_args = symbolize_args(options[:args])
		should_write = false

		if block_given?
			if method_args != :no_args && (result.nil? || result[method_args].nil?)
				result ||= {}
				result[method_args] = yield
				should_write = true
			elsif method_args == :no_args && result.nil?
				result = yield
				should_write = true
			end
		end

		write_to_cache(key_blob, result) if should_write
		
		result = (method_args == :no_args) ? result : result[method_args]
	end

	def self.multiple_fetch(key_blobs, &block)
		results = read_multi_from_cache(key_blobs)
		if results.nil?
			if block_given?
				results = yield
				write_multi_to_cache(results)
			end
		end
		results.values
	end

	##
	## READING FROM THE CACHE
	##

	def self.read_from_cache(key_blob)
		result = Rails.cache.read key_blob[:key]
		return result if result.nil?
		parse_with_key(result, key_blob[:type])
	end

	def self.read_multi_from_cache(key_blobs)
		keys = key_blobs.map { |blob| blob[:key] }
		results = Rails.cache.read_multi(*keys)
		return nil if results.values.all?(&:nil?)
		results.each do |key, value|
			type = key_blobs.select {|kb| kb.has_value?(key) }.first[:type]
			results[key] = parse_with_key(value, type)
		end
		results
	end

	###
	### WRITING TO THE CACHE
	###

	def self.write_multi_to_cache(keys_and_results)
		keys_and_results.each do |key, result|
			write_to_cache(key, result)
		end
	end

	def self.write_to_cache(key_blob, result)
		formatted_result = format_with_key(result, key_blob[:type])
		Rails.cache.write key_blob[:key], formatted_result
	end
end