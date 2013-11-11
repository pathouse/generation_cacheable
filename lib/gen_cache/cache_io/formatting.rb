module GenCache

	def self.format_with_key(result, key_type)
		return if result.nil?
		if key_type == :association
			result
		elsif key_type == :object
			formatted_result = format_object(result)
		else
			formatted_result = format_method(result)
		end
	end 

	## OBJECT FORMATTING ##

	def self.format_object(object)
		if object.is_a?(Array)
			object.map { |obj| coder_from_record(obj) }
		else
			coder_from_record(object)
		end
	end

	def self.coder_from_record(record)
		unless record.nil?
			coder = { :class => record.class }
			record.encode_with(coder)
			coder
		end
	end

	## METHOD FORMATTING ##
	def self.symbolize_args(args)
		return :no_args if args.nil? || args.empty?
		args.map do |arg|
			if arg.is_a?(Hash)
				arg.map {|k,v| "#{k}:#{v}"}.join(",")
			elsif arg.is_a?(Array)
				arg.join(",")
			else
				arg.to_s.split(" ").join("_")
			end
		end.join("+").to_sym
	end

	def self.escape_punctuation(string)
		string.sub(/\?\Z/, '_query').sub(/!\Z/, '_bang')
	end

	def self.detect_object(data)
		data.is_a?(ActiveRecord::Base) || 
		(data.is_a?(Array) && data[0].is_a?(ActiveRecord::Base))
	end

	def self.format_method(result)
		if detect_object(result)
			format_object(result)
		elsif result.is_a?(Hash)
			result.each do |arg_key, value|
				result[arg_key] = format_data(value)
			end
		else
			format_data(result)
		end
	end

	def self.format_data(result)
		if detect_object(result)
			format_object(result)
		else
			result
		end
	end

end