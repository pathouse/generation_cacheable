require 'spec_helper'

describe GenCache do
	let(:object)  { User.create(:login => 'flyerhzm') }
	let(:coder) { {:class => object.class, 'attributes' => object.attributes} }
  let(:fixnum) { 11 }
  let(:string) { "string cheese" }
  let(:hash) { {a: 1, b: 2, c: 3} }
  let(:array) { ['a','b','c'] }
  let(:bool) { true }

  context "methods" do

  	it "should correctly determine if a Hash is a coder" do
  		GenCache.hash_inspect(hash).should be_false
  		GenCache.hash_inspect(coder).should be_true
  	end

    it "should detect coders and coders in arrays" do
      GenCache.detect_coder(coder).should be_true
      GenCache.detect_coder([coder]).should be_true
    end

  	it "should correctly rebuild objects from coders" do
  		GenCache.parse_with_key(coder, :object).should == object
  	end

  	it "should rebuild multiple objects" do
      GenCache.parse_with_key([coder, coder], :object).should == [object, object]
  	end

  	it "should parse only the values of method results" do
  		arg1 = GenCache.symbolize_args([string,hash])
  		arg2 = GenCache.symbolize_args([array,bool])
  		method_result = { arg1 => [coder],
  											arg2 => string }
      parsed = GenCache.parse_with_key(method_result, :method)
      parsed[arg1].should == [object]
      parsed[arg2].should == string
  	end

  	it "should correctly parse methods without arguments" do
  		method_result = {"regular" => "hash"}
      GenCache.parse_with_key(method_result, :method).should == method_result
  	end
  end
end
