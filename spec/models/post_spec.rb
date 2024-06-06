require 'rails_helper'

RSpec.describe Post, type: :model do
  # 有効なファクトリを持つこと
  it "has a valid factory" do
    expect(FactoryBot.build_stubbed(:post)).to be_valid
  end

  # タイトル、本文、ユーザーがあれば有効な状態であること
  it "is valid with a title, body, and user" do
    post = FactoryBot.build_stubbed(:post)
    expect(post).to be_valid
  end

  # タイトルがなければ無効な状態であること
  it "is invalid without a title" do
    post = FactoryBot.build(:post, title: nil)
    post.valid?
    expect(post.errors[:title]).to include("can't be blank")
  end
  # タイトルが50文字以内でなければ無効な状態であること
  it "is invalid if the title exceeds 50 characters" do
    title = "a" * 51
    post = FactoryBot.build(:post, title: title)
    post.valid?
    expect(post.errors[:title]).to include("is too long (maximum is 50 characters)")
  end

  # 本文がなければ無効な状態であること
  it "is invalid without a body" do
    post = FactoryBot.build(:post, body: nil)
    post.valid?
    expect(post.errors[:body]).to include("can't be blank")
  end
  # 本文が10000文字以内でなければ無効な状態であること
  it "is invalid if the body exceeds 10000 characters" do
    body = "a" * 10001
    post = FactoryBot.build(:post, body: body)
    post.valid?
    expect(post.errors[:body]).to include("is too long (maximum is 10000 characters)")
  end

  # ユーザーIDがなければ無効な状態であること
  it "is invalid without a user_id" do
    post = FactoryBot.build(:post, user_id: nil)
    post.valid?
    expect(post.errors[:user_id]).to include("can't be blank")
  end
end
