require 'spec_helper'

describe GenCache do
  let(:cache) { Rails.cache }
  let(:user)  { User.create(:login => 'flyerhzm') }
  let(:descendant) { Descendant.create(:login => "scotterc")}

  before :all do
    @post1 = user.posts.create(:title => 'post1')
    user2 = User.create(:login => 'PelegR')
    user2.posts.create(:title => 'post3')
    @post3 = descendant.posts.create(:title => 'post3')
  end

  before :each do
    cache.clear
    user.reload
  end

  context "expire_model_cache" do
    it "should delete with_key cache" do
      User.find_cached(user.id)
      key = GenCache.instance_key(User, user.id)
      Rails.cache.read(key[:key]).should_not be_nil
      user.expire_all
      Rails.cache.read(key[:key]).should be_nil
    end

    it "should delete with_attribute cache" do
      user = User.find_cached_by_login("flyerhzm")
      key = GenCache.attribute_key(User, :login, "flyerhzm")
      Rails.cache.read(key[:key]).should == {:class => user.class, 'attributes' => user.attributes}
      user.expire_all
      Rails.cache.read(key[:key]).should be_nil
    end

    it "should delete with_method cache" do
      user.cached_last_post
      key = GenCache.method_key(user, :last_post)
      Rails.cache.read(key[:key]).should_not be_nil
      user.update_attribute(:login, "pathouse")
      key = GenCache.method_key(user, :last_post)
      Rails.cache.read(key[:key]).should be_nil
    end

    it "should delete with_class_method cache (default_post)" do
      Post.cached_default_post
      key = GenCache.class_method_key(Post, :default_post)
      Rails.cache.read(key[:key]).should_not be_nil
      @post1.expire_all
      Rails.cache.read(key[:key]).should be_nil
    end

    it "should delete with_class_method cache (retrieve_with_user_id)" do
      Post.cached_retrieve_with_user_id(1)
      key = GenCache.class_method_key(Post, :retrieve_with_user_id)
      Rails.cache.read(key[:key]).should_not be_nil
      @post1.expire_all
      Rails.cache.read(key[:key]).should be_nil
    end

    it "should delete with_class_method cache (retrieve_with_user_id) with different arguments" do
      Post.cached_retrieve_with_user_id(1)
      Post.cached_retrieve_with_user_id(2)
      key = GenCache.class_method_key(Post, :retrieve_with_user_id)
      Rails.cache.read(key[:key]).should_not be_nil
      @post1.expire_all
      Rails.cache.read(key[:key]).should be_nil
    end

    it "should delete with_class_method cache (retrieve_with_both)" do
      Post.cached_retrieve_with_both(1, 1)
      key = GenCache.class_method_key(Post, :retrieve_with_both)
      Rails.cache.read(key[:key]).should_not be_nil
      @post1.expire_all
      Rails.cache.read(key[:key]).should be_nil
    end

    it "should delete associations cache" do
      user.cached_images
      key = GenCache.association_key(user, :images)
      Rails.cache.read(key[:key]).should_not be_nil
      user.update_attribute(:login, 'pathouse')
      key = GenCache.association_key(user, :images)
      Rails.cache.read(key[:key]).should == []
    end
  end

  context "single table inheritance bug" do
    context "user" do
      it "has cached indices" do
        User.cached_indices.should_not be_nil
      end

      it "has specific cached indices" do
        User.cached_indices.keys.should include :login
        User.cached_indices.keys.should_not include :email
      end

      it "should have cached_methods" do
        User.cached_methods.should_not be_nil
        User.cached_methods.should == [:last_post, :bad_iv_name!, :bad_iv_name?]
      end
    end

    context "expiring class_method cache" do
      it "expires correctly from inherited attributes" do
        key = GenCache.class_method_key(User, :default_name)
        Rails.cache.read(key[:key]).should be_nil
        User.cached_default_name
        Rails.cache.read(key[:key]).should == "flyerhzm"
        user.expire_all
        Rails.cache.read(key[:key]).should be_nil
      end
    end

    context "descendant" do

      it "should have cached indices hash" do
        Descendant.cached_indices.should_not be_nil
      end

      it "has specific cached indices" do
        Descendant.cached_indices.keys.should include :login
        Descendant.cached_indices.keys.should include :email
      end

      it "should have cached_methods" do
        Descendant.cached_methods.should_not be_nil
        Descendant.cached_methods.should == [:last_post, :bad_iv_name!, :bad_iv_name?, :name]
      end

      context "expiring method cache" do
        it "expires correctly from inherited attributes" do
          key = GenCache.method_key(descendant, :last_post)
          Rails.cache.read(key[:key]).should be_nil
          descendant.cached_last_post.should == descendant.last_post
          Rails.cache.read(key[:key]).should == {:class => descendant.last_post.class, 'attributes' => descendant.last_post.attributes}
          descendant.update_attribute(:login, 'pathouse')
          key = GenCache.method_key(descendant, :last_post)
          Rails.cache.read(key[:key]).should be_nil
        end
      end

      context "expiring attribute cache" do
        it "expires correctly from inherited attributes" do
          descendant.update_attribute(:login, "scotterc")
          key = GenCache.attribute_key(Descendant, :login, "scotterc")
          Rails.cache.read(key[:key]).should be_nil
          Descendant.find_cached_by_login("scotterc").should == descendant
          Rails.cache.read(key[:key]).should == {:class => descendant.class, 'attributes' => descendant.attributes}
          descendant.expire_all
          Rails.cache.read(key[:key]).should be_nil
        end
      end

      context "expiring association cache" do
        it "expires correctly from inherited attributes" do
          key = GenCache.association_key(descendant, :posts)
          Rails.cache.read(key[:key]).should be_nil
          descendant.cached_posts.should == [@post3]
          Rails.cache.read(key[:key]).should == [GenCache.instance_key(Post, @post3.id)]
          descendant.update_attribute(:login, "pathouse")
          key = GenCache.association_key(descendant, :posts)
          Rails.cache.read(key[:key]).should be_nil
        end
      end

      context "expiring class_method cache" do
        it "expires correctly from inherited attributes" do
          key = GenCache.class_method_key(Descendant, :default_name)
          Rails.cache.read(key[:key]).should be_nil
          Descendant.cached_default_name
          Rails.cache.read(key[:key]).should == "ScotterC"
          descendant.expire_all
          Rails.cache.read(key[:key]).should be_nil
        end
      end
    end
  end

end