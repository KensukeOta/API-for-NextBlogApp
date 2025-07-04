require "rails_helper"

RSpec.describe UserSocialProfile, type: :model do
  # 正常系
  it "is valid with valid attributes" do
    profile = build(:user_social_profile)
    expect(profile).to be_valid
  end

  # providerがないと無効
  it "is invalid without a provider" do
    profile = build(:user_social_profile, provider: nil)
    expect(profile).not_to be_valid
    expect(profile.errors[:provider]).to include("can't be blank")
  end

  # userがいないと無効
  it "is invalid without a user" do
    profile = build(:user_social_profile, user: nil)
    expect(profile).not_to be_valid
    expect(profile.errors[:user]).to include("must exist")
  end

  # urlが空でも有効
  it "is valid with blank url" do
    profile = build(:user_social_profile, url: "")
    expect(profile).to be_valid
  end

  # urlが255文字以内なら有効
  it "is valid with url length <= 255" do
    base = "https://example.com/"
    max = 255
    long_url = base + "a" * (max - base.length)
    expect(long_url.length).to eq(255)
    profile = build(:user_social_profile, url: long_url)
    expect(profile).to be_valid
  end

  # urlが256文字以上だと無効
  it "is invalid if url is too long" do
    base = "https://example.com/"
    max = 255
    long_url = base + "a" * (max - base.length + 1)
    expect(long_url.length).to eq(256)
    profile = build(:user_social_profile, url: long_url)
    expect(profile).not_to be_valid
    expect(profile.errors[:url]).to include("is too long (maximum is 255 characters)")
  end

  # urlの形式が不正なら無効
  it "is invalid with an invalid url format" do
    profile = build(:user_social_profile, url: "invalid_url")
    expect(profile).not_to be_valid
    expect(profile.errors[:url]).to include("is invalid")
  end

  # 同じuserが同じproviderを2つ登録しようとすると無効
  it "is invalid if provider is duplicated for the same user" do
    user = create(:user)
    create(:user_social_profile, user: user, provider: "twitter")
    dup_profile = build(:user_social_profile, user: user, provider: "twitter")
    expect(dup_profile).not_to be_valid
    expect(dup_profile.errors[:provider]).to include("has already been taken")
  end

  # 異なるuserなら同じproviderを登録できる
  it "is valid if same provider is used by different users" do
    create(:user_social_profile, provider: "twitter")
    another_user = create(:user)
    profile = build(:user_social_profile, user: another_user, provider: "twitter")
    expect(profile).to be_valid
  end
end
