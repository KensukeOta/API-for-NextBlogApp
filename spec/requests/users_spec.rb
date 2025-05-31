require 'rails_helper'

RSpec.describe "Users", type: :request do
  describe "POST /v1/users" do
    let(:valid_attributes) do
      {
        name: "testuser",
        email: "testuser@example.com",
        provider: "credentials",
        password: "password123",
        password_confirmation: "password123",
        image: nil
      }
    end

    # ユーザー登録が成功すること
    # should create user successfully
    it "creates a user and returns status 201" do
      expect {
        post "/v1/users", params: { user: valid_attributes }
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["user"]["name"]).to eq("testuser")
      expect(json["user"]["email"]).to eq("testuser@example.com")
      expect(json["message"]).to eq("ユーザー登録が完了しました")
    end

    # email+providerが重複している場合はエラー
    # should return error when email+provider is duplicated
    it "returns error if email+provider already exists" do
      create(:user, email: "testuser@example.com", provider: "credentials")
      post "/v1/users", params: { user: valid_attributes }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("ユーザーは既に存在します")
    end

    # nameが重複している場合はエラー
    # should return error when name is duplicated
    it "returns error if name is already taken" do
      create(:user, name: "testuser")
      post "/v1/users", params: { user: valid_attributes.merge(email: "unique@example.com") }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("この名前は既に使用されています")
    end

    # バリデーションエラー（例：パスワードが短い場合）
    # should return error messages for validation errors
    it "returns validation errors for short password" do
      post "/v1/users", params: { user: valid_attributes.merge(password: "short", password_confirmation: "short") }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to include("Password is too short (minimum is 8 characters)")
    end
  end
end
