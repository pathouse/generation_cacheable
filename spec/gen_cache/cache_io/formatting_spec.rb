require 'spec_helper'

describe GenCache do
  let(:object)  { User.create(:login => 'flyerhzm') }
  let(:fixnum) { 11 }
  let(:string) { "string cheese" }
  let(:hash) { {a: 1, b: 2, c: 3} }
  let(:array) { ['a','b','c']}
  let(:bool) { true }

	context "methods" do

		it "should symbolize args correctly" do
			argsym = GenCache.symbolize_args([fixnum, string, hash, array])
			argsym.should == "11+string_cheese+a:1,b:2,c:3+a,b,c".to_sym
		end

		it "should escape method name punctuation correctly" do
			GenCache.escape_punctuation("holy_crap?").should == "holy_crap_query"
			GenCache.escape_punctuation("holy_crap!").should == "holy_crap_bang"
		end

		it "should format objects correctly" do
			GenCache.format_with_key(object, :object).should == { :class => object.class, 'attributes' => object.attributes}
		end

		it "should format multiple object correctly" do
			coder = { :class => object.class, 'attributes' => object.attributes}
			GenCache.format_with_key([object, object], :object).should == [coder, coder]
		end

		it "should format methods without arguments correctly" do
			GenCache.format_with_key(fixnum, :method).should == 11
		end

		it "should format method with arguments correctly" do
			arg1 = GenCache.symbolize_args([fixnum,string,hash])
			arg2 = GenCache.symbolize_args([string,hash,fixnum])
			to_be_formatted = { arg1 => object, 
													arg2 => object}
			formatted = GenCache.format_with_key(to_be_formatted, :method)
			formatted[arg1].should == {:class => object.class, 'attributes' => object.attributes }
			formatted[arg2].should == {:class => object.class, 'attributes' => object.attributes }
			formatted[arg1].should_not == object
			formatted[arg2].should_not == object
		end

		it "should format object correctly when returned from a method" do
			arg1 = GenCache.symbolize_args([fixnum,string])
			method_result = { arg1 => object }
			GenCache.format_with_key(method_result, :method).should == { arg1 => {:class => object.class, 'attributes' => object.attributes} }
		end
	end
end





