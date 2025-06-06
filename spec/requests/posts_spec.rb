require 'rails_helper'

RSpec.describe "Posts", type: :request do
  describe "GET /v1/posts" do
    let!(:user1) { create(:user, name: "user1", email: "user1@example.com") }
    let!(:user2) { create(:user, name: "user2", email: "user2@example.com") }
    let!(:old_post) { create(:post, title: "Oldest Post", user: user1, created_at: 1.day.ago) }
    let!(:new_post) { create(:post, title: "Newest Post", user: user2, created_at: Time.current) }

    # 全ての投稿が新しい順で返り、各投稿にユーザー情報が含まれることを検証
    it "returns all posts in descending order of creation, including user info" do
      get "/v1/posts"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      # JSON形式が { "posts": [ ... ] } であること
      expect(json).to have_key("posts")
      expect(json["posts"].size).to eq(2)

      # 新しい順で並んでいること
      expect(json["posts"][0]["title"]).to eq("Newest Post")
      expect(json["posts"][1]["title"]).to eq("Oldest Post")

      # ユーザー情報が正しく入っていること
      expect(json["posts"][0]["user"]["name"]).to eq("user2")
      expect(json["posts"][0]["user"]["email"]).to eq("user2@example.com")
      expect(json["posts"][1]["user"]["name"]).to eq("user1")
      expect(json["posts"][1]["user"]["email"]).to eq("user1@example.com")
    end

    # 投稿が存在しない場合は空配列が返ることを検証
    it "returns empty array if there are no posts" do
      Post.delete_all
      get "/v1/posts"
      json = JSON.parse(response.body)
      expect(json["posts"]).to eq([])
    end
  end

  describe "GET /v1/posts/:id" do
    # 記事とユーザーを用意
    let!(:user) { create(:user, name: "kensuke", email: "kensuke@example.com") }
    let!(:post) { create(:post, title: "Sample Post", content: "This is the post content.", user: user) }

    # 正常系: 存在する記事を取得できる
    # 記事の内容・ユーザー情報が返ってくることを検証
    it "returns a post with user info if post exists" do
      get "/v1/posts/#{post.id}"
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to have_key("post")
      expect(json["post"]["id"]).to eq(post.id)
      expect(json["post"]["title"]).to eq("Sample Post")
      expect(json["post"]["content"]).to eq("This is the post content.")
      expect(json["post"]["user"]["name"]).to eq("kensuke")
      expect(json["post"]["user"]["email"]).to eq("kensuke@example.com")
      expect(json["post"]["user"]["provider"]).to eq("credentials")
    end

    # 異常系: 存在しないIDを指定した場合
    it "returns 404 and error message if post does not exist" do
      get "/v1/posts/999999"
      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("記事が見つかりません")
    end
  end

  describe "POST /v1/posts" do
    # テストユーザーと投稿パラメータを準備
    let(:user) { create(:user) }
    let(:valid_attributes) {
      {
        post: {
          title: "RSpec Sample Post",
          content: "This is a test content with more than 10 chars."
        }
      }
    }
    let(:invalid_attributes) {
      {
        post: {
          title: "A", # too short
          content: "short"
        }
      }
    }

    # X-USER-IDヘッダーを付与するリクエスト用ヘルパー
    def auth_headers(user)
      { "X-USER-ID" => user.id.to_s }
    end

    # --------------------------------------------------------
    # テストケース
    # --------------------------------------------------------

    # 正常系
    # 記事が作成できる
    it "creates a post with valid params and returns 201" do
      expect {
        post "/v1/posts", params: valid_attributes, headers: auth_headers(user)
      }.to change(Post, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["post"]["title"]).to eq("RSpec Sample Post")
      expect(json["post"]["user_id"]).to eq(user.id)
    end

    # 異常系
    # 認証ヘッダーがない場合
    it "returns 401 if X-USER-ID header is missing" do
      post "/v1/posts", params: valid_attributes
      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("認証が必要です")
    end

    # 異常系
    # バリデーションエラーの場合
    it "returns 422 and error messages if params are invalid" do
      post "/v1/posts", params: invalid_attributes, headers: auth_headers(user)
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to include("Title is too short (minimum is 3 characters)")
      expect(json["errors"]).to include("Content is too short (minimum is 10 characters)")
    end

    # 異常系
    # 存在しないユーザーID
    it "returns 401 if X-USER-ID is invalid" do
      post "/v1/posts", params: valid_attributes, headers: { "X-USER-ID" => "999999" }
      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("認証が必要です")
    end
  end

  describe "PATCH /v1/posts/:id" do
    let!(:user)  { create(:user) }
    let!(:other) { create(:user) }
    let!(:post_record) { create(:post, user: user, title: "Old Title", content: "Old Content") }

    # 認証ヘッダーを付与するヘルパー
    def auth_headers(u)
      { "X-USER-ID" => u.id.to_s }
    end

    # 正常系: 自分の記事を更新できる
    # 更新後の内容が返却され、200となることを検証
    it "updates the post and returns the updated post if current_user is the owner" do
      patch "/v1/posts/#{post_record.id}",
        params: { post: { title: "New Title", content: "Updated Content" } },
        headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["post"]["title"]).to eq("New Title")
      expect(json["post"]["content"]).to eq("Updated Content")
      expect(json["post"]["user"]["id"]).to eq(user.id)
    end

    # 異常系: 記事が存在しない場合
    # 404とエラーメッセージを返すことを検証
    it "returns 404 if post does not exist" do
      patch "/v1/posts/999999",
        params: { post: { title: "Doesn't matter", content: "..." } },
        headers: auth_headers(user)

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("記事が見つかりません")
    end

    # 異常系: 他人の記事を更新しようとした場合
    # 403とエラーメッセージを返すことを検証
    it "returns 403 if current_user is not the owner" do
      patch "/v1/posts/#{post_record.id}",
        params: { post: { title: "Hacked Title", content: "..." } },
        headers: auth_headers(other)

      expect(response).to have_http_status(:forbidden)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("権限がありません")
    end

    # 異常系: バリデーションエラー
    # 422とエラーメッセージを返すことを検証
    it "returns 422 if params are invalid" do
      patch "/v1/posts/#{post_record.id}",
        params: { post: { title: "", content: "short" } },
        headers: auth_headers(user)

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to include("Title is too short (minimum is 3 characters)")
      expect(json["errors"]).to include("Content is too short (minimum is 10 characters)")
    end
  end

  describe "DELETE /v1/posts/:id" do
    let!(:user) { create(:user) }
    let!(:other_user) { create(:user) }
    let!(:post_record) { create(:post, user: user) }

    # 認証ヘッダーを付与するヘルパー
    def auth_headers(u)
      { "X-USER-ID" => u.id.to_s }
    end

    # 正常系: 投稿者自身なら削除できる
    it "deletes the post if current_user is the owner" do
      expect {
        delete "/v1/posts/#{post_record.id}", headers: auth_headers(user)
      }.to change(Post, :count).by(-1)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["message"]).to eq("記事を削除しました")
    end

    # 異常系: 存在しない記事ID
    it "returns 404 if the post does not exist" do
      expect {
        delete "/v1/posts/999999", headers: auth_headers(user)
      }.not_to change(Post, :count)

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("記事が見つかりません")
    end

    # 異常系: 他人の記事を削除しようとした場合
    it "returns 403 if current_user is not the owner" do
      expect {
        delete "/v1/posts/#{post_record.id}", headers: auth_headers(other_user)
      }.not_to change(Post, :count)

      expect(response).to have_http_status(:forbidden)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("権限がありません")
    end

    # 異常系: 認証ヘッダーがない場合
    it "returns 401 if X-USER-ID header is missing" do
      expect {
        delete "/v1/posts/#{post_record.id}"
      }.not_to change(Post, :count)

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("認証が必要です")
    end
  end
end
