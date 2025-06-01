require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  describe "POST /v1/sessions" do
    # テスト用のユーザーをFactoryBotで作成
    let(:user) { create(:user, password: "password123", password_confirmation: "password123") }

    # 正しい情報でログインできること
    it "returns user json and status 200 with correct credentials" do
      post "/v1/sessions", params: {
        user: {
          email: user.email,
          password: "password123",
          provider: user.provider
        }
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["user"]["id"]).to eq(user.id)
      expect(json["user"]["name"]).to eq(user.name)
      expect(json["user"]["email"]).to eq(user.email)
      expect(json["user"]["provider"]).to eq(user.provider)
      expect(json["user"]["image"]).to eq(user.image)
      # password_digest等は返されないこと
      expect(json["user"].key?("password_digest")).to be_falsey
    end

    # パスワードが間違っている場合は401になること
    it "returns 401 and error message if password is wrong" do
      post "/v1/sessions", params: {
        user: {
          email: user.email,
          password: "wrongpassword",
          provider: user.provider
        }
      }

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("ログインに失敗しました")
    end

    # emailが存在しない場合も401になること
    it "returns 401 and error message if email does not exist" do
      post "/v1/sessions", params: {
        user: {
          email: "notfound@example.com",
          password: "password123",
          provider: user.provider
        }
      }

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("ログインに失敗しました")
    end

    # providerが一致しない場合も401になること
    it "returns 401 and error message if provider does not match" do
      post "/v1/sessions", params: {
        user: {
          email: user.email,
          password: "password123",
          provider: "google" # userのproviderは"credentials"
        }
      }

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("ログインに失敗しました")
    end
  end
end
