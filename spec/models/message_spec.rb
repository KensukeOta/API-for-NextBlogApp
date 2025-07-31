require 'rails_helper'

RSpec.describe Message, type: :model do
  describe "Validation" do
    # 有効なファクトリでメッセージが有効であること
    it "is valid with a valid factory" do
      message = build(:message)
      expect(message).to be_valid
    end

    # contentが空だと無効
    it "is invalid without content" do
      message = build(:message, content: nil)
      expect(message).not_to be_valid
      expect(message.errors[:content]).to include("can't be blank")
    end

    # contentが1文字未満だと無効
    it "is invalid if content is less than 1 character" do
      message = build(:message, content: "")
      expect(message).not_to be_valid
      expect(message.errors[:content]).to include("is too short (minimum is 1 character)")
    end

    # contentが1000文字を超えると無効
    it "is invalid if content exceeds 1000 characters" do
      message = build(:message, content: "a" * 1001)
      expect(message).not_to be_valid
      expect(message.errors[:content]).to include("is too long (maximum is 1000 characters)")
    end

    # from_userがnilだと無効
    it "is invalid without a from_user" do
      message = build(:message, from_user: nil)
      expect(message).not_to be_valid
      expect(message.errors[:from_user]).to include("must exist")
    end

    # to_userがnilだと無効
    it "is invalid without a to_user" do
      message = build(:message, to_user: nil)
      expect(message).not_to be_valid
      expect(message.errors[:to_user]).to include("must exist")
    end
  end
end
