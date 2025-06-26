require "rails_helper"

RSpec.describe User, type: :model do
  describe "Validation" do
    # 有効なファクトリでユーザーが有効であること
    it "is valid with a valid factory" do
      user = build(:user)
      expect(user).to be_valid
    end

    # nameが空だと無効
    it "is invalid without a name" do
      user = build(:user, name: nil)
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("can't be blank")
    end

    # nameが3文字未満だと無効
    it "is invalid if name is less than 3 characters" do
      user = build(:user, name: "ab")
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("is too short (minimum is 3 characters)")
    end

    # nameが32文字を超えると無効
    it "is invalid if name exceeds 32 characters" do
      user = build(:user, name: "a" * 33)
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("is too long (maximum is 32 characters)")
    end

    # nameが重複していると無効
    it "is invalid if name is duplicated" do
      create(:user, name: "testuser")
      user = build(:user, name: "testuser")
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("has already been taken")
    end

    # emailが空だと無効
    it "is invalid without an email" do
      user = build(:user, email: nil)
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    # emailが重複（同一provider）だと無効
    it "is invalid if email is duplicated for the same provider" do
      create(:user, email: "duplicate@example.com", provider: "credentials")
      user = build(:user, email: "duplicate@example.com", provider: "credentials")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("has already been taken")
    end

    # emailが重複でもproviderが異なれば有効
    it "is valid if email is duplicated but provider is different" do
      create(:user, email: "multi@example.com", provider: "google")
      user = build(:user, email: "multi@example.com", provider: "credentials")
      expect(user).to be_valid
    end

    # emailの形式が不正だと無効
    it "is invalid with invalid email format" do
      user = build(:user, email: "invalid_email")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("is invalid")
    end

    # providerが空だと無効
    it "is invalid without a provider" do
      user = build(:user, provider: nil)
      expect(user).not_to be_valid
      expect(user.errors[:provider]).to include("can't be blank")
    end

    # passwordが8文字未満だと無効
    it "is invalid if password is less than 8 characters" do
      user = build(:user, password: "short", password_confirmation: "short")
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("is too short (minimum is 8 characters)")
    end

    # passwordが64文字を超えると無効
    it "is invalid if password exceeds 64 characters" do
      pwd = "a" * 65
      user = build(:user, password: pwd, password_confirmation: pwd)
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("is too long (maximum is 64 characters)")
    end

    # passwordとpassword_confirmationが一致しないと無効
    it "is invalid if password and password_confirmation do not match" do
      user = build(:user, password: "password123", password_confirmation: "different123")
      expect(user).not_to be_valid
      expect(user.errors[:password_confirmation]).to include("doesn't match Password")
    end

    # imageはnilでも有効
    it "is valid if image is nil" do
      user = build(:user, image: nil)
      expect(user).to be_valid
    end

    # bioが200文字以内なら有効
    it "is valid if bio is 200 characters or less" do
      user = build(:user, bio: "a" * 200)
      expect(user).to be_valid
    end

    # bioが201文字を超えると無効
    it "is invalid if bio exceeds 200 characters" do
      user = build(:user, bio: "a" * 201)
      expect(user).not_to be_valid
      expect(user.errors[:bio]).to include("is too long (maximum is 200 characters)")
    end

    # bioがnilでも有効
    it "is valid if bio is nil" do
      user = build(:user, bio: nil)
      expect(user).to be_valid
    end
  end
end
