require "rails_helper"

RSpec.describe Tag, type: :model do
  describe "Validation" do
    # 有効なファクトリなら有効である
    it "is valid with a valid factory" do
      tag = build(:tag)
      expect(tag).to be_valid
    end

    # nameが空の場合は無効
    it "is invalid without a name" do
      tag = build(:tag, name: "")
      expect(tag).to be_invalid
      expect(tag.errors[:name]).to include("can't be blank")
    end

    # nameが重複している場合は無効
    it "is invalid with a duplicate name" do
      create(:tag, name: "Ruby")
      dup_tag = build(:tag, name: "Ruby")
      expect(dup_tag).to be_invalid
      expect(dup_tag.errors[:name]).to include("has already been taken")
    end

    # nameが10文字を超える場合は無効
    it "is invalid if name is longer than 10 characters" do
      tag = build(:tag, name: "a" * 11)
      expect(tag).to be_invalid
      expect(tag.errors[:name]).to include("is too long (maximum is 10 characters)")
    end
  end

  describe "Association" do
    # user_tagsの関連があること
    it "has user_tags association" do
      tag = create(:tag)
      user_tag = create(:user_tag, tag: tag)
      expect(tag.user_tags).to include(user_tag)
    end

    # usersの関連があること
    it "has users association" do
      tag = create(:tag)
      user = create(:user)
      create(:user_tag, user: user, tag: tag)
      expect(tag.users).to include(user)
    end

    # post_tagsの関連があること
    it "has post_tags association" do
      tag = create(:tag)
      post_tag = create(:post_tag, tag: tag)
      expect(tag.post_tags).to include(post_tag)
    end

    # postsの関連があること
    it "has posts association" do
      tag = create(:tag)
      post = create(:post)
      create(:post_tag, post: post, tag: tag)
      expect(tag.posts).to include(post)
    end
  end
end
