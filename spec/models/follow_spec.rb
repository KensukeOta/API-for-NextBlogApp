require 'rails_helper'

RSpec.describe Follow, type: :model do
  describe "Validation" do
    # 有効なファクトリでフォローが有効であること
    it "is valid with a valid factory" do
      follower = create(:user)
      followed = create(:user)
      follow = build(:follow, follower: follower, followed: followed)
      expect(follow).to be_valid
    end

    # 同じユーザーを2回フォローできない
    it "is invalid if the follower follows the same user twice" do
      follower = create(:user)
      followed = create(:user)
      create(:follow, follower: follower, followed: followed)
      duplicate_follow = build(:follow, follower: follower, followed: followed)
      expect(duplicate_follow).not_to be_valid
      expect(duplicate_follow.errors[:follower_id]).to include("has already been taken")
    end

    # 自分自身をフォローできない
    it "is invalid if the follower follows themselves" do
      user = create(:user)
      follow = build(:follow, follower: user, followed: user)
      expect(follow).not_to be_valid
      expect(follow.errors[:follower_id]).to include("can't follow yourself")
    end

    # followerがnilの場合は無効
    it "is invalid without a follower" do
      follow = build(:follow, follower: nil)
      expect(follow).not_to be_valid
      expect(follow.errors[:follower]).to include("must exist")
    end

    # followedがnilの場合は無効
    it "is invalid without a followed user" do
      follow = build(:follow, followed: nil)
      expect(follow).not_to be_valid
      expect(follow.errors[:followed]).to include("must exist")
    end
  end
end
