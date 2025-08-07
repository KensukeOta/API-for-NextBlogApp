require 'rails_helper'

RSpec.describe "Timeline", type: :request do
  # JWTヘッダー発行ヘルパー
  def jwt_auth_headers(user)
    token = JsonWebToken.encode(user_id: user.id)
    { "Authorization" => "Bearer #{token}" }
  end

  describe "GET /v1/timeline" do
    let!(:user)      { create(:user, name: "mainuser", email: "main@example.com") }
    let!(:followee1) { create(:user, name: "followee1", email: "f1@example.com") }
    let!(:followee2) { create(:user, name: "followee2", email: "f2@example.com") }
    let!(:not_followee) { create(:user, name: "outsider", email: "out@example.com") }

    # mainuserが2人をフォロー
    let!(:follow1) { create(:follow, follower: user, followed: followee1) }
    let!(:follow2) { create(:follow, follower: user, followed: followee2) }

    # 各ユーザーに投稿を用意
    let!(:my_post1) { create(:post, user: user, title: "my newest", created_at: 1.hour.ago) }
    let!(:my_post2) { create(:post, user: user, title: "my oldest", created_at: 3.hours.ago) }
    let!(:f1_post)  { create(:post, user: followee1, title: "f1 post", created_at: 2.hours.ago) }
    let!(:f2_post)  { create(:post, user: followee2, title: "f2 post", created_at: 4.hours.ago) }
    let!(:out_post) { create(:post, user: not_followee, title: "not in timeline", created_at: 5.hours.ago) }

    # タグも付与
    let!(:tag1) { create(:tag, name: "Ruby") }
    let!(:tag2) { create(:tag, name: "Rails") }
    before do
      my_post1.tags << tag1
      f1_post.tags << [ tag1, tag2 ]
      # 他はタグなし
    end

    # 正常系: フォロー＋自分の投稿が新しい順で返る
    it "returns posts by self and followed users in descending order" do
      get "/v1/timeline", headers: jwt_auth_headers(user)
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      # 投稿数（my_post1, my_post2, f1_post, f2_post）
      expect(json["posts"].length).to eq(4)
      # 新しい順
      expect(json["posts"].map { |p| p["title"] }).to eq([
        "my newest",   # 1h前
        "f1 post",     # 2h前
        "my oldest",   # 3h前
        "f2 post"      # 4h前
      ])
      # outsiderの投稿は含まれない
      expect(json["posts"].map { |p| p["title"] }).not_to include("not in timeline")

      # user, tags, likes情報が含まれているか（最低限確認）
      post = json["posts"].find { |p| p["title"] == "my newest" }
      expect(post["user"]["name"]).to eq("mainuser")
      expect(post["tags"].map { |t| t["name"] }).to eq([ "Ruby" ])
      expect(post["likes"]).to be_a(Array)
    end

    # フォローも自分投稿もない場合
    it "returns empty array if there are no posts" do
      # 新規ユーザー
      lonely = create(:user)
      get "/v1/timeline", headers: jwt_auth_headers(lonely)
      json = JSON.parse(response.body)
      expect(json["posts"]).to eq([])
    end

    # 認証されていない場合
    it "returns 401 if unauthorized" do
      get "/v1/timeline"
      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("認証が必要です")
    end
  end
end
