require 'rails_helper'

RSpec.describe "Likes", type: :request do
  # JWTヘッダー発行ヘルパー
  def jwt_auth_headers(user)
    token = JsonWebToken.encode(user_id: user.id)
    { "Authorization" => "Bearer #{token}" }
  end

  let(:user) { create(:user) }
  let(:post_record) { create(:post) }

  describe "POST /v1/likes" do
    # いいね作成（正常系）
    it "creates a like for a post" do
      expect {
        post "/v1/likes", params: { like: { post_id: post_record.id } }, headers: jwt_auth_headers(user)
      }.to change(Like, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["message"]).to eq("いいねしました")
      expect(json["like"]["user_id"]).to eq(user.id)
      expect(json["like"]["post_id"]).to eq(post_record.id)
    end

    # 既に同じ投稿をいいね済みの場合
    it "returns a message if already liked" do
      create(:like, user: user, post: post_record)

      expect {
        post "/v1/likes", params: { like: { post_id: post_record.id } }, headers: jwt_auth_headers(user)
      }.not_to change(Like, :count)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["message"]).to eq("すでにいいねしています")
    end

    # 記事が存在しない場合
    it "returns not found if post does not exist" do
      expect {
        post "/v1/likes", params: { like: { post_id: "nonexistent" } }, headers: jwt_auth_headers(user)
      }.not_to change(Like, :count)

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("記事が見つかりません")
    end

    # ログインしていない（ヘッダーがない）場合
    it "returns unauthorized if user is not logged in" do
      post "/v1/likes", params: { like: { post_id: post_record.id } } # headersなし

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("認証が必要です")
    end

    # 無効なトークンのテスト
    it "returns unauthorized if token is invalid" do
      post "/v1/likes", params: { like: { post_id: post_record.id } }, headers: { "Authorization" => "Bearer invalidtoken" }
      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("認証が必要です")
    end
  end

  describe "DELETE /v1/likes/:id" do
    # いいね削除（正常系）
    it "deletes a like" do
      like = create(:like, user: user, post: post_record)
      expect {
        delete "/v1/likes/#{like.id}", headers: jwt_auth_headers(user)
      }.to change(Like, :count).by(-1)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["message"]).to eq("いいねを解除しました")
    end

    # 他人のいいねは削除できない
    it "does not delete another user's like" do
      other_user = create(:user)
      other_like = create(:like, user: other_user, post: post_record)

      expect {
        delete "/v1/likes/#{other_like.id}", headers: jwt_auth_headers(user)
      }.not_to change(Like, :count)

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("いいねが見つかりません")
    end

    # いいね自体が存在しない場合
    it "returns not found if like does not exist" do
      expect {
        delete "/v1/likes/999999", headers: jwt_auth_headers(user)
      }.not_to change(Like, :count)

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("いいねが見つかりません")
    end

    # ログインしていない（ヘッダーがない）場合
    it "returns unauthorized if user is not logged in" do
      like = create(:like, user: user, post: post_record)
      delete "/v1/likes/#{like.id}" # headersなし

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("認証が必要です")
    end

    # 無効なトークンのテスト
    it "returns unauthorized if token is invalid" do
      like = create(:like, user: user, post: post_record)
      delete "/v1/likes/#{like.id}", headers: { "Authorization" => "Bearer invalidtoken" }
      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("認証が必要です")
    end
  end
end
