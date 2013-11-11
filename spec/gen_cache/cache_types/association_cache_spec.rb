require 'spec_helper'

describe GenCache do
  let(:cache) { Rails.cache }
  let(:user)  { User.create(:login => 'flyerhzm') }
  let(:user2)  { User.create(:login => 'ScotterC') }


  before :all do
    @post1 = user.posts.create(:title => 'post1')
    @post2 = user.posts.create(:title => 'post2')
    @post3 = Post.create
    @image1 = @post1.images.create
    @image2 = @post1.images.create
    @comment1 = @post1.comments.create
    @comment2 = @post1.comments.create
    @tag1 = @post1.tags.create(title: "Rails")
    @tag2 = @post1.tags.create(title: "Caching")
    @group1 = Group.create(name: "Ruby On Rails")
    @account = user.create_account(group: @group1)
    @location = @post1.create_location(city: "New York")
  end

  before :each do
    cache.clear
    user.reload
  end

  context "with_association" do
    before :each do
      @post1.instance_variable_set("@cached_user", nil)
      @comment1.instance_variable_set("@cached_commentable", nil)
    end

    context "belongs_to" do
      it "should not cache association" do
        key = GenCache.association_key(@post1, :user)
        Rails.cache.read(key[:key]).should be_nil
      end

      it "should cache Post#user" do
        @post1.cached_user.should == user
        key = GenCache.association_key(@post1, :user)
        Rails.cache.read(key[:key]).should == [GenCache.instance_key(User, user.id)]
      end

      it "should cache Post#user multiple times" do
        @post1.cached_user
        @post1.cached_user.should == user
      end

      it "should cache Comment#commentable with polymorphic" do
        key = GenCache.association_key(@comment1, :commentable)
        Rails.cache.read(key[:key]).should be_nil
        @comment1.cached_commentable.should == @post1
        Rails.cache.read(key[:key]).should == [GenCache.instance_key(Post, @post1.id)]
      end

      it "should return nil if there are none" do
        @post3.cached_user.should be_nil
      end
    end

    context "has_many" do
      it "should not cache associations" do
        key = GenCache.association_key(user, :posts)
        Rails.cache.read(key[:key]).should be_nil
      end

      it "should cache User#posts" do
        user.cached_posts.should == [@post1, @post2]
        key = GenCache.association_key(user, :posts)
        Rails.cache.read(key[:key]).should == [GenCache.instance_key(Post, @post1.id), 
                                               GenCache.instance_key(Post, @post2.id)]
      end

      it "should cache User#posts multiple times" do
        user.cached_posts
        user.cached_posts.should == [@post1, @post2]
      end

      it "should return empty if there are none" do
        user2.cached_posts.should == []
      end
    end

    context "has_many with polymorphic" do
      it "should not cache associations" do
        key = GenCache.association_key(@post1, :comments)
        Rails.cache.read(key[:key]).should be_nil
      end

      it "should cache Post#comments" do
        @post1.cached_comments.should == [@comment1, @comment2]
        key = GenCache.association_key(@post1, :comments)
        Rails.cache.read(key[:key]).should == [GenCache.instance_key(Comment, @comment1.id), 
                                               GenCache.instance_key(Comment, @comment2.id)]
      end

      it "should cache Post#comments multiple times" do
        @post1.cached_comments
        @post1.cached_comments.should == [@comment1, @comment2]
      end

      it "should return empty if there are none" do
        @post3.cached_comments.should == []
      end
    end

    context "has_one" do
      it "should not cache associations" do
        key = GenCache.association_key(user, :account)
        Rails.cache.read(key[:key]).should be_nil
      end

      it "should cache User#posts" do
        user.cached_account.should == @account
        key = GenCache.association_key(user, :account)
        Rails.cache.read(key[:key]).should == [GenCache.instance_key(Account, @account.id)]
      end

      it "should cache User#posts multiple times" do
        user.cached_account
        user.cached_account.should == @account
      end

      it "should return nil if there are none" do
        user2.cached_account.should be_nil
      end
    end

    context "has_many through" do
      it "should not cache associations" do
        key = GenCache.association_key(user, :images)
        Rails.cache.read(key[:key]).should be_nil
      end

      it "should cache User#images" do
        user.cached_images.should == [@image1, @image2]
        key = GenCache.association_key(user, :images)
        Rails.cache.read(key[:key]).should == [GenCache.instance_key(Image, @image1.id), 
                                               GenCache.instance_key(Image, @image2.id)]
      end

      it "should cache User#images multiple times" do
        user.cached_images
        user.cached_images.should == [@image1, @image2]
      end

      context "expiry" do
        before :each do
          user.instance_variable_set("@cached_images", nil)
        end

        it "should have the correct collection" do
          @image3 = @post1.images.create
          key = GenCache.association_key(user, :images)
          Rails.cache.read(key[:key]).should be_nil
          user.cached_images.should == [@image1, @image2, @image3]
          Rails.cache.read(key[:key]).should == [GenCache.instance_key(Image, @image1.id), 
                                                 GenCache.instance_key(Image, @image2.id), 
                                                 GenCache.instance_key(Image, @image3.id)]
        end
      end

      it "should return empty if there are none" do
        user2.cached_images.should == []
      end
    end

    context "has_one through belongs_to" do
      it "should not cache associations" do
        key = GenCache.association_key(user, :group)
        Rails.cache.read(key[:key]).should be_nil
      end

      it "should cache User#group" do
        user.cached_group.should == @group1
        key = GenCache.association_key(user, :group)
        Rails.cache.read(key[:key]).should == [GenCache.instance_key(Group, @group1.id)]
      end

      it "should cache User#group multiple times" do
        user.cached_group
        user.cached_group.should == @group1
      end

      it "should return nil if there are none" do
        user2.cached_group.should be_nil
      end

    end

    context "has_and_belongs_to_many" do

      it "should not cache associations off the bat" do
        key = GenCache.association_key(@post1, :tags)
        Rails.cache.read(key[:key]).should be_nil
      end

      it "should cache Post#tags" do
        @post1.cached_tags.should == [@tag1, @tag2]
        key = GenCache.association_key(@post1, :tags)
        Rails.cache.read(key[:key]).should == [GenCache.instance_key(Tag, @tag1.id),
                                               GenCache.instance_key(Tag, @tag2.id)]
      end

      it "should handle multiple requests" do
        @post1.cached_tags
        @post1.cached_tags.should == [@tag1, @tag2]
      end

      it "should return empty if there are none" do
        @post3.cached_tags.should == []
      end

      context "expiry" do
        before :each do
          @post1.instance_variable_set("@cached_tags", nil)
        end

        it "should have the correct collection" do
          @tag3 = @post1.tags.create!(title: "Invalidation is hard")
          key = GenCache.association_key(@post1, :tags)
          Rails.cache.read(key[:key]).should be_nil
          @post1.cached_tags.should == [@tag1, @tag2, @tag3]
          Rails.cache.read(key[:key]).should == [GenCache.instance_key(Tag, @tag1.id),
                                                 GenCache.instance_key(Tag, @tag2.id), 
                                                 GenCache.instance_key(Tag, @tag3.id)]
        end
      end
    end
  end

  describe "memoization" do
    describe "belongs to" do
      before :each do
        @post1.instance_variable_set("@cached_user", nil)
        @post1.update_attribute(:title, rand(10000).to_s)
      end

      it "memoizes cache calls" do
        @post1.instance_variable_get("@cached_user").should be_nil
        @post1.cached_user.should == @post1.user
        @post1.instance_variable_get("@cached_user").should == @post1.user
      end

      it "hits the cache only once" do
        Rails.cache.expects(:read).once
        @post1.cached_user.should == @post1.user
        @post1.cached_user.should == @post1.user
      end
    end

    describe "has through" do
      before :each do
        user.instance_variable_set("@cached_images", nil)
        user.update_attribute(:login, rand(10000).to_s)
      end

      it "memoizes cache calls" do
        user.instance_variable_get("@cached_images").should be_nil
        user.cached_images.should == user.images
        user.instance_variable_get("@cached_images").should == user.images
      end

      it "hits the cache only once" do
        Rails.cache.expects(:read)
        user.cached_images.should == user.images
        user.cached_images.should == user.images
      end
    end

    describe "has and belongs to many" do
      before :each do
        @post1.instance_variable_set("@cached_tags", nil)
        @post1.update_attribute(:title, rand(10000).to_s)
      end

      it "memoizes cache calls" do
        @post1.instance_variable_get("@cached_tags").should be_nil
        @post1.cached_tags.should == @post1.tags
        @post1.instance_variable_get("@cached_tags").should == @post1.tags
      end

      it "hits the cache only once" do
        Rails.cache.expects(:read)
        @post1.cached_tags.should == @post1.tags
        @post1.cached_tags.should == @post1.tags
      end
    end

    describe "one to many" do
      before :each do
        user.instance_variable_set("@cached_posts", nil)
        user.update_attribute(:login, rand(10000).to_s)
      end

      it "memoizes cache calls" do
        user.instance_variable_get("@cached_posts").should be_nil
        user.cached_posts.should == user.posts
        user.instance_variable_get("@cached_posts").should == user.posts
      end

      it "hits the cache only once" do
        Rails.cache.expects(:read)
        user.cached_posts.should == user.posts
        user.cached_posts.should == user.posts
      end
    end
  end

end