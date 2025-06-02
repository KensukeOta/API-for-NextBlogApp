require 'rails_helper'

RSpec.describe "Oauths", type: :request do
  describe "POST /v1/oauth" do
    # 既存ユーザー（email+provider一致）がいる場合はそのまま返す
    it "returns existing user if email and provider already exist" do
      user = create(:user, email: "oauth@example.com", provider: "google", name: "taro")
      post "/v1/oauth", params: {
        user: {
          name: "taro",
          email: "oauth@example.com",
          provider: "google",
          image: "http://example.com/avatar.png"
        }
      }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["user"]["id"]).to eq(user.id)
      expect(json["user"]["email"]).to eq(user.email)
      expect(json["user"]["provider"]).to eq(user.provider)
      expect(json["user"]["name"]).to eq(user.name)
      expect(json["user"]["image"]).to eq("http://example.com/avatar.png").or eq(user.image)
    end

    # nameが既に存在する場合は、ランダムな接尾辞でユニークなnameになること
    it "creates a user with a unique name if name is already taken" do
      create(:user, name: "taro")  # 既存の同名ユーザー
      post "/v1/oauth", params: {
        user: {
          name: "taro",
          email: "new_oauth@example.com",
          provider: "google",
          image: "http://example.com/avatar.png"
        }
      }
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["user"]["name"]).to match(/\Ataro_[A-Za-z0-9]{6}\z/)  # taro_XXXXXX形式
      expect(User.find_by(email: "new_oauth@example.com", provider: "google")).not_to be_nil
    end

    # nameが重複していなければ、そのまま登録されること
    it "creates a user with the given name if name is not taken" do
      post "/v1/oauth", params: {
        user: {
          name: "unique_name",
          email: "unique@example.com",
          provider: "google",
          image: "http://example.com/avatar.png"
        }
      }
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["user"]["name"]).to eq("unique_name")
      expect(User.find_by(email: "unique@example.com", provider: "google")).not_to be_nil
    end

    # name, email, providerが全て空の場合はバリデーションエラー
    it "returns errors if required fields are missing" do
      post "/v1/oauth", params: { user: { name: "", email: "", provider: "", image: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["error"]).to be_an(Array)
    end
  end
end
