require "rails_helper"

RSpec.describe Post, type: :model do
  describe "Validation" do
    # 有効なファクトリでポストが有効であること
    it "is valid with a valid factory" do
      post = build(:post)
      expect(post).to be_valid
    end

    # titleが空だと無効
    it "is invalid without a title" do
      post = build(:post, title: nil)
      expect(post).not_to be_valid
      expect(post.errors[:title]).to include("can't be blank")
    end

    # titleが3文字未満だと無効
    it "is invalid if title is less than 3 characters" do
      post = build(:post, title: "ab")
      expect(post).not_to be_valid
      expect(post.errors[:title]).to include("is too short (minimum is 3 characters)")
    end

    # titleが50文字を超えると無効
    it "is invalid if title exceeds 50 characters" do
      post = build(:post, title: "a" * 51)
      expect(post).not_to be_valid
      expect(post.errors[:title]).to include("is too long (maximum is 50 characters)")
    end

    # contentが空だと無効
    it "is invalid without content" do
      post = build(:post, content: nil)
      expect(post).not_to be_valid
      expect(post.errors[:content]).to include("can't be blank")
    end

    # contentが10文字未満だと無効
    it "is invalid if content is less than 10 characters" do
      post = build(:post, content: "a" * 9)
      expect(post).not_to be_valid
      expect(post.errors[:content]).to include("is too short (minimum is 10 characters)")
    end

    # contentが10000文字を超えると無効
    it "is invalid if content exceeds 10000 characters" do
      post = build(:post, content: "a" * 10001)
      expect(post).not_to be_valid
      expect(post.errors[:content]).to include("is too long (maximum is 10000 characters)")
    end

    # userがnilだと無効
    it "is invalid without a user" do
      post = build(:post, user: nil)
      expect(post).not_to be_valid
      expect(post.errors[:user]).to include("must exist")
    end
  end
end
