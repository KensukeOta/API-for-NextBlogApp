require 'rails_helper'

RSpec.describe "Follows", type: :request do
  # JWTヘッダー発行ヘルパー
  def jwt_auth_headers(user)
    token = JsonWebToken.encode(user_id: user.id)
    { "Authorization" => "Bearer #{token}" }
  end

  describe "POST /v1/follows" do
    let!(:user) { create(:user) }
    let!(:other_user) { create(:user) }

    # 正常系: フォローできる
    it "creates a follow and returns 201" do
      expect {
        post "/v1/follows", params: { follow: { followed_id: other_user.id } }, headers: jwt_auth_headers(user)
      }.to change(Follow, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["message"]).to eq("フォローしました")
    end

    # 異常系: 認証がない場合
    it "returns 401 if not authenticated" do
      post "/v1/follows", params: { follow: { followed_id: other_user.id } }
      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("認証が必要です")
    end

    # 異常系: 存在しないユーザーID
    it "returns 404 if user to follow does not exist" do
      post "/v1/follows", params: { follow: { followed_id: 99999 } }, headers: jwt_auth_headers(user)
      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("ユーザーが見つかりません")
    end

    # 異常系: すでにフォロー済みの場合
    it "returns 422 if already followed" do
      create(:follow, follower: user, followed: other_user)
      post "/v1/follows", params: { follow: { followed_id: other_user.id } }, headers: jwt_auth_headers(user)
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to include("Follower has already been taken")
    end

    # 異常系: 自分自身をフォローしようとした場合
    it "returns 422 if trying to follow yourself" do
      post "/v1/follows", params: { follow: { followed_id: user.id } }, headers: jwt_auth_headers(user)
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to include("Follower can't follow yourself")
    end
  end

  describe "DELETE /v1/follows/:id" do
    let!(:user) { create(:user) }
    let!(:other_user) { create(:user) }
    let!(:follow) { create(:follow, follower: user, followed: other_user) }

    # 正常系: フォロー解除できる
    it "deletes the follow and returns success message" do
      expect {
        delete "/v1/follows/#{follow.id}", headers: jwt_auth_headers(user)
      }.to change(Follow, :count).by(-1)
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["message"]).to eq("フォローを解除しました")
    end

    # 異常系: 認証がない場合
    it "returns 401 if not authenticated" do
      delete "/v1/follows/#{follow.id}"
      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("認証が必要です")
    end

    # 異常系: フォロー関係が存在しない場合
    it "returns 404 if follow relationship does not exist" do
      delete "/v1/follows/99999", headers: jwt_auth_headers(user)
      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("フォロー関係が見つかりません")
    end

    # 異常系: 他人のフォローを削除しようとした場合
    it "returns 404 if trying to delete someone else's follow" do
      other_follow = create(:follow, follower: other_user, followed: user)
      delete "/v1/follows/#{other_follow.id}", headers: jwt_auth_headers(user)
      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("フォロー関係が見つかりません")
    end
  end

  describe "GET /v1/users/:id/followers" do
    let!(:user) { create(:user) }
    let!(:follower1) { create(:user) }
    let!(:follower2) { create(:user) }
    let!(:follow1) { create(:follow, follower: follower1, followed: user) }
    let!(:follow2) { create(:follow, follower: follower2, followed: user) }

    # フォロワー一覧が返る
    it "returns the followers list" do
      get "/v1/users/#{user.id}/followers", headers: jwt_auth_headers(user)
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to have_key("followers")
      ids = json["followers"].map { |f| f["id"] }
      expect(ids).to include(follower1.id, follower2.id)
      expect(json["followers"].all? { |f| f["name"].present? }).to be true
    end
  end

  describe "GET /v1/users/:id/following" do
    let!(:user) { create(:user) }
    let!(:other_user1) { create(:user) }
    let!(:other_user2) { create(:user) }
    let!(:follow1) { create(:follow, follower: user, followed: other_user1) }
    let!(:follow2) { create(:follow, follower: user, followed: other_user2) }

    # フォロー中一覧が返る
    it "returns the following list" do
      get "/v1/users/#{user.id}/following", headers: jwt_auth_headers(user)
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to have_key("following")
      ids = json["following"].map { |f| f["id"] }
      expect(ids).to include(other_user1.id, other_user2.id)
      expect(json["following"].all? { |f| f["name"].present? }).to be true
    end
  end
end
