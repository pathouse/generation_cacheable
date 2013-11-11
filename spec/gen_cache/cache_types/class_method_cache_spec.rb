require 'spec_helper'

describe GenCache do
  let(:cache) { Rails.cache }
  let(:user)  { User.create(:login => 'flyerhzm', :email => 'flyerhzm@mail.com') }

  before :all do
    @post1 = user.posts.create(:title => 'post1')
    @post2 = user.posts.create(:title => 'post2')
  end

  before :each do
    cache.clear
    user.reload
  end

  it "should not cache Post.default_post" do
    key = GenCache.class_method_key(Post, :default_post)
    Rails.cache.read(key[:key]).should be_nil
  end

  it "should cache Post.default_post" do
    key = GenCache.class_method_key(Post, :default_post)
    Post.cached_default_post.should == @post1
    Rails.cache.read(key[:key]).should == {:class => @post1.class, 'attributes' => @post1.attributes}
  end

  it "should cache Post.default_post multiple times" do
    Post.cached_default_post
    Post.cached_default_post.should == @post1
  end

  it "should cache Post.retrieve_with_user_id" do
    result = Post.cached_retrieve_with_user_id(1)
    Post.cached_retrieve_with_user_id(1).should == @post1
    key = GenCache.class_method_key(Post, :retrieve_with_user_id)
    Rails.cache.read(key[:key]).should == {:"1" => {:class => @post1.class, 'attributes' => @post1.attributes }}
  end

  it "should cache Post.retrieve_with_both with multiple arguments" do
    Post.cached_retrieve_with_both(1, 1).should be_true
    key = GenCache.class_method_key(Post, :retrieve_with_both)
    Rails.cache.read(key[:key]).should == { :"1+1" => true }
  end

  describe "marshalling" do

    it "should handle methods with a number argument" do
      result = User.cached_user_with_id(1)
      key = GenCache.class_method_key(User, :user_with_id)
      Rails.cache.read(key[:key]).should == {:"1" => {:class => user.class, 'attributes' => user.attributes }}
    end

    it "should handle methods with a string argument" do
      result = User.cached_user_with_email("flyerhzm@mail.com")
      key = GenCache.class_method_key(User, :user_with_email)
      Rails.cache.read(key[:key]).should == {:"flyerhzm@mail.com" => {:class => user.class, 'attributes' => user.attributes} }
    end

    it "should handle methods with an array argument" do
      result = User.cached_users_with_ids([ 1 ])
      key = GenCache.class_method_key(User, :users_with_ids)
      Rails.cache.read(key[:key]).should == {:"1" => [{:class => user.class, 'attributes' => user.attributes}]}
    end

    it "should handle methods with a range argument" do
      result = User.cached_users_with_ids_in( (1...3) )
      key = GenCache.class_method_key(User, "users_with_ids_in")
      Rails.cache.read(key[:key]).should == {:"1...3" => [{:class => user.class, 'attributes' => user.attributes }] }
    end
  end
end