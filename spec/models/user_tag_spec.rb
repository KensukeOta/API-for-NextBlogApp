require 'rails_helper'

RSpec.describe UserTag, type: :model do
  describe "Validation" do
  # 有効なファクトリなら有効
  it "is valid with a valid factory" do
    expect(build(:user_tag)).to be_valid
  end

  # user_idとtag_idの組み合わせが重複している場合は無効
  it "is invalid if user_id and tag_id combination is duplicated" do
    user = create(:user)
    tag = create(:tag)
    create(:user_tag, user: user, tag: tag)
    dup_user_tag = build(:user_tag, user: user, tag: tag)
    expect(dup_user_tag).to be_invalid
    expect(dup_user_tag.errors[:user_id]).to include("has already been taken")
  end

  # userがない場合は無効
  it "is invalid without user" do
    expect(build(:user_tag, user: nil)).not_to be_valid
  end

  # tagがない場合は無効
  it "is invalid without tag" do
    expect(build(:user_tag, tag: nil)).not_to be_valid
  end

  describe "Association" do
    # userとtagの関連があること
    it "has user and tag association" do
      user_tag = create(:user_tag)
      expect(user_tag.user).to be_a(User)
      expect(user_tag.tag).to be_a(Tag)
    end
  end
  end
end
