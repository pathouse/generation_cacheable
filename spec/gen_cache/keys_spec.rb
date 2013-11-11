require 'spec_helper'

describe GenCache do
	let(:cache) { Rails.cache }
  let(:user)  { User.create(:login => 'flyerhzm') }

	context "methods" do

		it "should generate a model prefix" do
			schema_string = User.columns.sort_by(&:name).map { |c| "#{c.name}:#{c.type}"}.join(",")
			schema_hash = CityHash.hash64(schema_string)
			prefix = GenCache.model_prefix(User)
			prefix.should == "users/#{schema_hash}"
		end

		it "should generate an instance prefix" do
			attribute_string = user.attributes.sort.map { |k,v| [k,v].join(":")}.join(",")
			attribute_hash = CityHash.hash64(attribute_string)
			prefix = GenCache.instance_prefix(user)
			prefix.should == GenCache.model_prefix(User) + "/#{user.id.to_s}/#{attribute_hash}"
		end

		it "should generate an instance key" do
			expected_key = {type: :object, key: GenCache.model_prefix(User) + "/#{user.id.to_s}"}
			GenCache.instance_key(User, user.id).should == expected_key
		end

		it "should generate an attribute key" do
			expected_key = {type: :object, key: GenCache.model_prefix(User) + '/login/pathouse'}
			att_key = GenCache.attribute_key(User, :login, ['pathouse'])
			att_key.should == expected_key
		end

		it "should generate an all w/ attribute key" do
			expected_key = {type: :object, key: GenCache.model_prefix(User) + "/all/login/pathouse"}
			att_key = GenCache.attribute_key(User, :login, ['pathouse'], all: true)
			att_key.should == expected_key
		end

		it "should generate a class method key" do
			expected_key = {type: :method, key: GenCache.model_prefix(User) + "/default_name"}
			cmethod_key = GenCache.class_method_key(User, :default_name)
			cmethod_key.should == expected_key
		end

		it "should return all class method keys" do
			all_cmethod_keys = GenCache.all_class_method_keys(User)
			comparison = User.cached_class_methods.map do |cmeth|
				GenCache.class_method_key(User, cmeth)
			end
			all_cmethod_keys.should == comparison
		end

		it "should generate a method key" do
			expected_key = {type: :method, key: GenCache.instance_prefix(user) + "/last_post"}
			method_key = GenCache.method_key(user, :last_post)
			method_key.should == expected_key
		end

		it "should generate an association key" do
			expected_key = {type: :association, key: GenCache.instance_prefix(user) + "/posts"}
			assoc_key = GenCache.association_key(user, :posts)
			assoc_key.should == expected_key
		end
	end
end