require 'spec_helper'

describe GenCache do
  let(:cache) { Rails.cache }
  let(:user)  { User.create(:login => 'flyerhzm') }
  let(:descendant) { Descendant.create(:login => "scotterc")}

  before :all do
    @post1 = user.posts.create(:title => 'post1')
    @post2 = user.posts.create(:title => 'post2')
    @post3 = descendant.posts.create(:title => 'post3')
  end

  before :each do
    cache.clear
    user.reload
  end

  context "with_attribute" do
    it "should not cache User.find_by_login" do
      key = GenCache.attribute_key(User, :login, "flyerhzm")
      Rails.cache.read(key[:key]).should be_nil
    end

    it "should cache by User.find_by_login" do
      User.find_cached_by_login("flyerhzm").should == user
      key = GenCache.attribute_key(User, :login, 'flyerhzm')
      Rails.cache.read(key[:key]).should == {:class => user.class, 'attributes' => user.attributes}
    end

    it "should get cached by User.find_by_login multiple times" do
      User.find_cached_by_login("flyerhzm")
      User.find_cached_by_login("flyerhzm").should == user
    end

    it "should escape whitespace" do
      new_user = User.create(:login => "user space")
      User.find_cached_by_login("user space").should == new_user
    end

    it "should handle fixed numbers" do
      Post.find_cached_by_user_id(user.id).should == @post1
      key = GenCache.attribute_key(Post, :user_id, user.id)
      Rails.cache.read(key[:key]).should == {:class => @post1.class, 'attributes' => @post1.attributes}
    end

    context "find_all" do
      it "should not cache Post.find_all_by_user_id" do
        key = GenCache.attribute_key(Post, :user_id, user.id, all: true)
        Rails.cache.read(key[:key]).should be_nil
      end

      it "should cache by Post.find_cached_all_by_user_id" do
        Post.find_cached_all_by_user_id(user.id).should == [@post1, @post2]
        key = GenCache.attribute_key(Post, :user_id, user.id, all: true)
        Rails.cache.read(key[:key]).should == [{:class => Post, 'attributes' => @post1.attributes},
                                                                              {:class => Post, 'attributes' => @post2.attributes}]
      end

      it "should get cached by Post.find_cached_all_by_user_id multiple times" do
        Post.find_cached_all_by_user_id(user.id)
        Post.find_cached_all_by_user_id(user.id).should == [@post1, @post2]
      end

    end
  end

  context "descendant" do
    it "should not cache Descendant.find_by_login" do
      key = GenCache.attribute_key(Descendant, :login, "scotterc")
      Rails.cache.read(key[:key]).should be_nil
    end

    it "should cache by Descendant.find_by_login" do
      Descendant.find_cached_by_login("scotterc").should == descendant
      key = GenCache.attribute_key(Descendant, :login, "scotterc")
      Rails.cache.read(key[:key]).should == {:class => Descendant, 'attributes' => descendant.attributes}
    end

    it "should get cached by Descendant.find_by_login multiple times" do
      Descendant.find_cached_by_login("scotterc")
      Descendant.find_cached_by_login("scotterc").should == descendant
    end

    it "should escape whitespace" do
      new_descendant = Descendant.create(:login => "descendant space")
      Descendant.find_cached_by_login("descendant space").should == new_descendant
    end

    it "maintains cached methods" do
      key = GenCache.method_key(descendant, :name)
      Rails.cache.read(key[:key]).should be_nil
      descendant.cached_name.should == descendant.name
      Rails.cache.read(key[:key]).should == descendant.name
    end
  end

end