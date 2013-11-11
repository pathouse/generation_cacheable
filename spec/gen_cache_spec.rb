require 'spec_helper'

describe Cacheable do
  let(:cache) { Rails.cache }
  let(:user)  { User.create(:login => 'flyerhzm') }

  before :all do
    @group1 = Group.create(name: "Ruby On Rails")
    @account = user.create_account(group: @group1)
    @post1 = user.posts.create(:title => 'post1')
    @image1 = @post1.images.create
    @comment1 = @post1.comments.create
    @tag1 = @post1.tags.create(title: "Rails")
  end

  before :each do
    cache.clear
    user.reload
  end

  context "Association Expires on Save" do
    it "should delete has_many with_association cache" do
      user.cached_posts
      key = Cacheable.association_key(user, :posts)
      Rails.cache.read(key[:key]).should_not be_nil
      @post1.update_attribute(:title, "Blarg")
      old_key = Rails.cache.read(key[:key]).first
      Rails.cache.read(old_key[:key]).should be_nil
    end

    it "should delete has_many with polymorphic with_association cache" do
      @post1.cached_comments
      key = Cacheable.association_key(@post1, :comments)
      Rails.cache.read(key[:key]).should_not be_nil
      @comment1.update_attribute(:commentable_type, "fart")
      old_key = Rails.cache.read(key[:key]).first
      Rails.cache.read(old_key[:key]).should be_nil
    end

    it "should delete has_many through with_association cache" do
      user.cached_images
      key = Cacheable.association_key(user, :images)
      Rails.cache.read(key[:key]).should_not be_nil
      @image1.update_attribute(:viewable_type, "Gralb")
      old_key = Rails.cache.read(key[:key]).first
      Rails.cache.read(old_key[:key]).should be_nil
    end

    it "should delete has_one with_association cache" do
      user.cached_account
      key = Cacheable.association_key(user, :account)
      Rails.cache.read(key[:key]).should_not be_nil
      @account.update_attribute(:group_id, 7)
      old_key = Rails.cache.read(key[:key]).first
      Rails.cache.read(old_key[:key]).should be_nil
    end

    it "should delete has_and_belongs_to_many with_association cache" do
      @post1.cached_tags
      key = Cacheable.association_key(@post1, :tags)
      Rails.cache.read(key[:key]).should_not be_nil
      old_key = Rails.cache.read(key[:key]).first
      @tag1.update_attribute(:title, "new title")
      Rails.cache.read(old_key[:key]).should be_nil
    end

    it "should delete has_one through belongs_to with_association cache" do
      @account.update_attribute(:group_id, 1)
      @group1.update_attribute(:name, "Poop Group")
      key = Cacheable.association_key(user, :group)
      Rails.cache.read(key[:key]).should be_nil
      user.cached_group.should == @group1
      Rails.cache.read(key[:key]).should == [Cacheable.instance_key(Group, @group1.id)]
    end
  end
end
