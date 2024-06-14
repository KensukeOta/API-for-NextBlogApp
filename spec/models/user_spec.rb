require 'rails_helper'

RSpec.describe User, type: :model do
   # 有効なファクトリを持つこと
  it "has a valid factory" do
    expect(FactoryBot.build_stubbed(:user)).to be_valid
  end
    
  # uid, 名前、メールアドレス、パスワード、確認用パスワード、プロバイダーがあれば有効な状態であること
  it "is valid with a uid, name, email, password, password_confirmation and provider" do
    user = FactoryBot.build(:user)
    expect(user).to be_valid
  end

  # 名前がなければ無効な状態であること
  it "is invalid without a name" do
    user = FactoryBot.build(:user, name: nil)
    user.valid?
    expect(user.errors[:name]).to include("can't be blank")
  end
  # 名前が2文字以上でなければ無効な状態であること
  it "is invalid if the name is not at least 2 characters long" do
    name = "a" * 1
    user = FactoryBot.build(:user, name: name)
    user.valid?
    expect(user.errors[:name]).to include("is too short (minimum is 2 characters)")
  end
  # 名前が50文字以内でなければ無効な状態であること
  it "is invalid if the name exceeds 50 characters" do
    name = "a" * 51
    user = FactoryBot.build(:user, name: name)
    user.valid?
    expect(user.errors[:name]).to include("is too long (maximum is 50 characters)")
  end

  # メールアドレスがなければ無効な状態であること
  it "is invalid without a email" do
    user = FactoryBot.build(:user, email: nil)
    user.valid?
    expect(user.errors[:email]).to include("can't be blank")
  end
  # メールアドレスが254文字以内でなければ無効な状態であること
  it "is invalid if the email exceeds 254 characters" do
    email = "a" * 255
    user = FactoryBot.build(:user, email: email)
    user.valid?
    expect(user.errors[:email]).to include("is too long (maximum is 254 characters)")
  end
  # メールアドレスの形式が間違っていれば無効な状態であること
  it "is invalid if the email format is incorrect" do
    email = "hoge"
    user = FactoryBot.build(:user, email: email)
    user.valid?
    expect(user.errors[:email]).to include("is invalid")
  end

  # パスワードがなければ無効な状態であること
  it "is invalid without a password" do
    user = FactoryBot.build(:user, password: nil)
    user.valid?
    expect(user.errors[:password]).to include("can't be blank")
  end
  # パスワードが8文字以上でなければ無効な状態であること
  it "is invalid if the password is not at least 8 characters long" do
    password = "a" * 7
    user = FactoryBot.build(:user, password: password)
    user.valid?
    expect(user.errors[:password]).to include("is too short (minimum is 8 characters)")
  end
  # パスワードが32文字以内でなければ無効な状態であること
  it "is invalid if the password exceeds 32 characters" do
    password = "a" * 33
    user = FactoryBot.build(:user, password: password)
    user.valid?
    expect(user.errors[:password]).to include("is too long (maximum is 32 characters)")
  end

  # 確認用パスワードがなければ無効な状態であること
  it "is invalid without a password_confirmation" do
    user = FactoryBot.build(:user, password_confirmation: nil)
    user.valid?
    expect(user.errors[:password_confirmation]).to include("can't be blank")
  end

  # パスワードと確認用パスワードが一致しなければ無効な状態であること
  it "is invalid if the password and password confirmation do not match" do
    user = FactoryBot.build(:user, password: "hogefuga", password_confirmation: "hogefugapiyo")
    user.valid?
    expect(user.errors[:password_confirmation]).to include("doesn't match Password")
  end
end
