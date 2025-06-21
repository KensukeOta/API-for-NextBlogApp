require 'rails_helper'

RSpec.describe Like, type: :model do
  # Likeのバリデーションと関連のテスト

  # 正常系
  # userとpostがあれば有効
  it "is valid with a user and a post" do
    like = build(:like)
    expect(like).to be_valid
  end

  # 異常系
  # userがなければ無効
  it "is invalid without a user" do
    like = build(:like, user: nil)
    expect(like).not_to be_valid
    expect(like.errors[:user]).to be_present
  end

  # postがなければ無効
  it "is invalid without a post" do
    like = build(:like, post: nil)
    expect(like).not_to be_valid
    expect(like.errors[:post]).to be_present
  end

  # 同じユーザーが同じ記事に2回いいねできない
  it "is invalid if the same user likes the same post twice" do
    user = create(:user)
    post = create(:post)
    create(:like, user: user, post: post)
    duplicate_like = build(:like, user: user, post: post)
    expect(duplicate_like).not_to be_valid
    expect(duplicate_like.errors[:user_id]).to include("has already been taken")
  end

  # 関連の確認
  it "belongs to user" do
    assoc = described_class.reflect_on_association(:user)
    expect(assoc.macro).to eq :belongs_to
  end

  it "belongs to post" do
    assoc = described_class.reflect_on_association(:post)
    expect(assoc.macro).to eq :belongs_to
  end
end
