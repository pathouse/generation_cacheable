require 'spec_helper'

describe GenCache do
  let(:cache) { Rails.cache }
  let(:user)  { User.create(:login => 'flyerhzm') }

  before :each do
    cache.clear
    user.reload
  end

  it "should not cache key" do
    cache_key = GenCache.instance_key(User, user.id)
    Rails.cache.read(cache_key[:key]).should be_nil
  end

  it "should cache by User#id" do
    User.find_cached(user.id).should == user
    cache_key = GenCache.instance_key(User, user.id)
    Rails.cache.read(cache_key[:key]).should == {:class => user.class, 'attributes' => user.attributes}
  end

  it "should parse formatted cache read successfully" do
    User.find_cached(user.id)
    cache_key = GenCache.instance_key(User, user.id)
    GenCache.fetch(cache_key).should == user
  end

  it "should get cached by User#id multiple times" do
    User.find_cached(user.id)
    User.find_cached(user.id).should == user
  end

end