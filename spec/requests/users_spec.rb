require 'rails_helper'

RSpec.describe "Users", type: :request do
  describe "GET /v1/users/:name (show_by_name)" do
    let(:user) { create(:user, name: "showtestuser", bio: "自己紹介テストです。") }

    # ユーザーが存在し、そのユーザーに3件の記事が紐づいている場合
    # 各記事には異なるcreated_atを与える
    let!(:post1) { create(:post, user: user, title: "Oldest Post", created_at: 3.days.ago) }
    let!(:post2) { create(:post, user: user, title: "Middle Post", created_at: 2.days.ago) }
    let!(:post3) { create(:post, user: user, title: "Newest Post", created_at: 1.day.ago) }
    let(:posts) { [ post1, post2, post3 ] }

    # 他ユーザー＆他記事も用意
    let!(:other_user) { create(:user, name: "otheruser") }
    let!(:other_post1) { create(:post, user: other_user, title: "Other Post1", created_at: 4.days.ago) }
    let!(:other_post2) { create(:post, user: other_user, title: "Other Post2", created_at: 2.hours.ago) }

    # いいねを付与（異なるcreated_atでいいね順をテスト）
    let!(:like1) { create(:like, user: user, post: other_post1, created_at: 5.hours.ago) }
    let!(:like2) { create(:like, user: user, post: other_post2, created_at: 1.hour.ago) }
    let(:liked_posts) { [ other_post2, other_post1 ] } # 新しい順

    # ユーザー情報・記事情報・記事ごとのuser情報・新しい順で返却されることと、いいねした記事がいいねした新しい順に返却されること
    it "returns user info, posts (newest first), and liked_posts (by liked_at desc)" do
      get "/v1/users/#{user.name}"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      # ユーザー情報を検証
      expect(json["user"]["id"]).to eq(user.id)
      expect(json["user"]["name"]).to eq(user.name)
      expect(json["user"]["email"]).to eq(user.email)
      expect(json["user"]["provider"]).to eq(user.provider)
      expect(json["user"]["image"]).to eq(user.image)
      expect(json["user"]["bio"]).to eq("自己紹介テストです。")

      # 投稿記事の数と内容を検証
      expect(json["user"]["posts"].size).to eq(3)

      # 新しい順で返っていることを検証
      expected_titles = posts.sort_by(&:created_at).reverse.map(&:title)
      returned_titles = json["user"]["posts"].map { |p| p["title"] }
      expect(returned_titles).to eq(expected_titles)

      # 各記事のuser情報も検証
      json["user"]["posts"].each do |post_json|
        post_user = post_json["user"]
        expect(post_user["id"]).to eq(user.id)
        expect(post_user["name"]).to eq(user.name)
        expect(post_user["email"]).to eq(user.email)
        expect(post_user["provider"]).to eq(user.provider)
        expect(post_user["image"]).to eq(user.image)
      end

      # liked_postsが新しい順（likeのcreated_at降順）で返っていること
      liked_titles = json["user"]["liked_posts"].map { |p| p["title"] }
      expect(liked_titles).to eq(liked_posts.map(&:title))

      # liked_postsにliked_atが含まれていること
      liked_at_array = json["user"]["liked_posts"].map { |p| p["liked_at"] }
      expect(liked_at_array.size).to eq(2)
      expect(Time.parse(liked_at_array[0])).to be > Time.parse(liked_at_array[1])

      # liked_posts各記事のuser情報
      json["user"]["liked_posts"].each do |post_json|
        post_user = post_json["user"]
        # いいね先のuser情報（other_user）かつ、プロパティ検証
        expect(post_user).not_to be_nil
        expect(post_user["id"]).not_to eq(user.id) # 他ユーザー
        expect(post_user["name"]).to be_present
      end
    end

    # ユーザーが存在しない場合
    it "returns 404 when the user does not exist" do
      get "/v1/users/nonexistentuser"
      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("ユーザーが見つかりません")
    end

    # 記事が1件も存在しない場合
    # postsが空配列になることを確認
    it "returns user info with empty posts and liked_posts array when user has no posts or likes" do
      # 別ユーザーを作成（投稿は作成しない）
      user_without_posts = create(:user, name: "nopostuser")
      get "/v1/users/#{user_without_posts.name}"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["user"]["posts"]).to eq([])
      expect(json["user"]["liked_posts"]).to eq([])
    end

    it "returns bio as nil if not set" do
      user_without_bio = create(:user, name: "nobiouser", bio: nil)
      get "/v1/users/#{user_without_bio.name}"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["user"]["bio"]).to be_nil
    end
  end

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

  describe "PATCH /v1/users/:id" do
    let!(:user) { create(:user, name: "original_name", email: "user@example.com", bio: "old bio") }
    let(:headers) { { "X-USER-ID" => user.id } }

    # 他のユーザー（権限チェックや重複名チェック用）
    let!(:other_user) { create(:user, name: "taken_name") }

    # 正常系：自分の情報を更新できる
    it "updates own user info successfully" do
      patch "/v1/users/#{user.id}", params: {
        user: {
          name: "new_name",
          bio: "new bio"
        }
      }, headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["user"]["id"]).to eq(user.id)
      expect(json["user"]["name"]).to eq("new_name")
      expect(json["user"]["bio"]).to eq("new bio")
      expect(json["message"]).to eq("ユーザー情報を更新しました")
    end

    # 異常系：存在しないユーザーIDを指定した場合
    it "returns 404 if user does not exist" do
      patch "/v1/users/00000000-0000-0000-0000-000000000000", params: {
        user: { name: "any", bio: "any" }
      }, headers: headers

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("ユーザーが見つかりません")
    end

    # 異常系：他人の情報は更新できない
    it "returns forbidden if trying to update another user" do
      patch "/v1/users/#{other_user.id}", params: {
        user: { name: "changed", bio: "changed" }
      }, headers: headers

      expect(response).to have_http_status(:forbidden)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("権限がありません")
    end

    # 異常系：ユーザー名が重複している場合
    it "returns error if name is already taken by another user" do
      patch "/v1/users/#{user.id}", params: {
        user: { name: "taken_name", bio: "any" }
      }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("この名前は既に使用されています")
    end

    # 異常系：バリデーションエラー（例：名前が短すぎる場合）
    it "returns validation errors if params are invalid" do
      patch "/v1/users/#{user.id}", params: {
        user: { name: "a", bio: "b" }
      }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to include("Name is too short (minimum is 3 characters)")
    end

    # 異常系：認証ヘッダーがない場合
    it "returns unauthorized if header is missing" do
      patch "/v1/users/#{user.id}", params: {
        user: { name: "noheader", bio: "noheader" }
      }
      # headersなし

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("認証が必要です")
    end
  end

  describe "DELETE /v1/users/:id" do
    # テストユーザー・ヘッダー
    let!(:user) { create(:user, name: "delete_user") }
    let(:headers) { { "X-USER-ID" => user.id } }

    # 他のユーザー（権限確認用）
    let!(:other_user) { create(:user, name: "otheruser") }

    # 正常系：自分のユーザーを削除できる
    it "deletes own user successfully" do
      expect {
        delete "/v1/users/#{user.id}", headers: headers
      }.to change(User, :count).by(-1)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["message"]).to eq("ユーザーを削除しました")
    end

    # 異常系：存在しないユーザーIDを指定した場合
    it "returns 404 if user does not exist" do
      expect {
        delete "/v1/users/00000000-0000-0000-0000-000000000000", headers: headers
      }.not_to change(User, :count)

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("ユーザーが見つかりません")
    end

    # 異常系：他人のユーザーを削除しようとした場合
    it "returns forbidden if trying to delete another user" do
      expect {
        delete "/v1/users/#{other_user.id}", headers: headers
      }.not_to change(User, :count)

      expect(response).to have_http_status(:forbidden)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("権限がありません")
    end

    # 異常系：認証ヘッダーがない場合
    it "returns unauthorized if header is missing" do
      delete "/v1/users/#{user.id}"
      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("認証が必要です")
    end
  end
end
