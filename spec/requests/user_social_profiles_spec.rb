require 'rails_helper'

RSpec.describe "UserSocialProfiles", type: :request do
  let!(:user) { create(:user) }
  let(:headers) { { "X-USER-ID" => user.id } }

  # 別ユーザー（権限チェック用）
  let!(:other_user) { create(:user) }

  describe "POST /v1/user_social_profiles" do
    # SNS情報を新規登録できる
    it "creates a new SNS profile" do
      expect {
        post "/v1/user_social_profiles", params: {
          user_social_profile: { provider: "twitter", url: "https://twitter.com/user" }
        }, headers: headers
      }.to change(UserSocialProfile, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["user_social_profile"]["provider"]).to eq("twitter")
      expect(json["user_social_profile"]["url"]).to eq("https://twitter.com/user")
      expect(json["message"]).to eq("SNS情報を登録しました")
    end

    # バリデーションエラー
    it "returns validation errors for invalid params" do
      post "/v1/user_social_profiles", params: {
        user_social_profile: { provider: "", url: "invalid_url" }
      }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to include("Provider can't be blank")
      expect(json["errors"]).to include("Url is invalid")
    end

    # 認証ヘッダーがない場合
    it "returns unauthorized if user is not logged in" do
      post "/v1/user_social_profiles", params: {
        user_social_profile: { provider: "twitter", url: "https://twitter.com/user" }
      }
      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("認証が必要です")
    end
  end

  describe "PATCH /v1/user_social_profiles/:id" do
    let!(:profile) { create(:user_social_profile, user: user, provider: "twitter", url: "https://twitter.com/old") }

    # 自分のSNS情報を更新できる
    it "updates own SNS profile" do
      patch "/v1/user_social_profiles/#{profile.id}", params: {
        user_social_profile: { provider: "twitter", url: "https://twitter.com/new" }
      }, headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["user_social_profile"]["url"]).to eq("https://twitter.com/new")
      expect(json["message"]).to eq("SNS情報を更新しました")
    end

    # 存在しないID
    it "returns not found if profile does not exist" do
      patch "/v1/user_social_profiles/00000000-0000-0000-0000-000000000000", params: {
        user_social_profile: { provider: "twitter", url: "https://twitter.com/new" }
      }, headers: headers

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("SNS情報が見つかりません")
    end

    # 他人のSNS情報を編集できない
    it "returns forbidden if trying to update another user's profile" do
      other_profile = create(:user_social_profile, user: other_user, provider: "facebook", url: "https://facebook.com/other")
      patch "/v1/user_social_profiles/#{other_profile.id}", params: {
        user_social_profile: { provider: "facebook", url: "https://facebook.com/hacker" }
      }, headers: headers

      expect(response).to have_http_status(:forbidden)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("権限がありません")
    end

    # バリデーションエラー
    it "returns validation errors for invalid params" do
      patch "/v1/user_social_profiles/#{profile.id}", params: {
        user_social_profile: { provider: "", url: "not a url" }
      }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to include("Provider can't be blank")
      expect(json["errors"]).to include("Url is invalid")
    end

    # 認証ヘッダーがない場合
    it "returns unauthorized if header is missing" do
      patch "/v1/user_social_profiles/#{profile.id}", params: {
        user_social_profile: { provider: "twitter", url: "https://twitter.com/hacker" }
      }
      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("認証が必要です")
    end
  end

  describe "DELETE /v1/user_social_profiles/:id" do
    let!(:profile) { create(:user_social_profile, user: user) }

    # 自分のSNS情報を削除できる
    it "deletes own SNS profile" do
      expect {
        delete "/v1/user_social_profiles/#{profile.id}", headers: headers
      }.to change(UserSocialProfile, :count).by(-1)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["message"]).to eq("SNS情報を削除しました")
    end

    # 存在しないID
    it "returns not found if profile does not exist" do
      delete "/v1/user_social_profiles/00000000-0000-0000-0000-000000000000", headers: headers
      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("SNS情報が見つかりません")
    end

    # 他人のSNS情報を削除できない
    it "returns forbidden if trying to delete another user's profile" do
      other_profile = create(:user_social_profile, user: other_user)
      delete "/v1/user_social_profiles/#{other_profile.id}", headers: headers

      expect(response).to have_http_status(:forbidden)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("権限がありません")
    end

    # 認証ヘッダーがない場合
    it "returns unauthorized if header is missing" do
      delete "/v1/user_social_profiles/#{profile.id}"
      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("認証が必要です")
    end
  end
end
