require 'rails_helper'

RSpec.describe "Users", type: :request do
  # JWTヘッダー発行ヘルパー
  def jwt_auth_headers(user)
    token = JsonWebToken.encode(user_id: user.id)
    { "Authorization" => "Bearer #{token}" }
  end

  # 任意サイズ・任意MIMEのアップロードファイルを生成
  def build_uploaded_file(bytes:, content_type:, filename:)
    tmp = Tempfile.new([ "upload", File.extname(filename) ])
    tmp.binmode
    tmp.write("a" * bytes)
    tmp.rewind
    Rack::Test::UploadedFile.new(tmp.path, content_type, original_filename: filename)
  end

  describe "GET /v1/users/:name (show_by_name)" do
    let(:user) { create(:user, name: "showtestuser", bio: "自己紹介テストです。") }

    # ユーザーが存在し、そのユーザーに3件の記事が紐づいている場合
    # 各記事には異なるcreated_atを与える
    let!(:post1) { create(:post, user: user, title: "Oldest Post", created_at: 3.days.ago) }
    let!(:post2) { create(:post, user: user, title: "Middle Post", created_at: 2.days.ago) }
    let!(:post3) { create(:post, user: user, title: "Newest Post", created_at: 1.day.ago) }
    let(:posts) { [ post1, post2, post3 ] }

    # --- ここでタグを用意し、記事に関連付け ---
    let!(:tag_ruby)   { Tag.create!(name: "Ruby") }
    let!(:tag_react)  { Tag.create!(name: "React") }
    let!(:tag_other)  { Tag.create!(name: "Other") }
    before do
      post1.tags << tag_ruby
      post2.tags << [ tag_react, tag_other ]
      # post3はタグなし
    end

    # ユーザー用タグを用意し付与
    let!(:user_tag1) { Tag.create!(name: "TypeScript") }
    let!(:user_tag2) { Tag.create!(name: "Rails") }
    before do
      user.tags << [ user_tag1, user_tag2 ]
    end

    # SNS情報も用意
    let!(:twitter_profile)  { create(:user_social_profile, user: user, provider: "twitter",  url: "https://x.com/testuser") }
    let!(:youtube_profile)  { create(:user_social_profile, user: user, provider: "youtube",  url: "https://youtube.com/testuser") }
    let!(:instagram_profile) { create(:user_social_profile, user: user, provider: "instagram", url: "https://instagram.com/testuser") }

    # 他ユーザー＆他記事も用意
    let!(:other_user) { create(:user, name: "otheruser") }
    let!(:other_post1) { create(:post, user: other_user, title: "Other Post1", created_at: 4.days.ago) }
    let!(:other_post2) { create(:post, user: other_user, title: "Other Post2", created_at: 2.hours.ago) }

    # いいねを付与（異なるcreated_atでいいね順をテスト）
    let!(:like1) { create(:like, user: user, post: other_post1, created_at: 5.hours.ago) }
    let!(:like2) { create(:like, user: user, post: other_post2, created_at: 1.hour.ago) }
    let(:liked_posts) { [ other_post2, other_post1 ] } # 新しい順

    # --- フォロー/フォロワー関連 ---
    let!(:follower1) { create(:user, name: "follower1") }
    let!(:follower2) { create(:user, name: "follower2") }
    let!(:follower_rel1) { create(:follow, follower: follower1, followed: user, created_at: 3.hours.ago) }
    let!(:follower_rel2) { create(:follow, follower: follower2, followed: user, created_at: 1.hour.ago) }

    let!(:following1) { create(:user, name: "following1") }
    let!(:following2) { create(:user, name: "following2") }
    let!(:following_rel1) { create(:follow, follower: user, followed: following1, created_at: 2.hours.ago) }
    let!(:following_rel2) { create(:follow, follower: user, followed: following2, created_at: 4.hours.ago) }

    # ユーザー情報・記事情報・記事ごとのuser情報・新しい順で返却されることと、いいねした記事がいいねした新しい順に返却されることと、フォローしているユーザーとフォロワーが新しい順に返却されること
    it "returns user info, posts (newest first, including tags), user_social_profiles, user tags, liked_posts (by liked_at desc), followers, and following (newest first), with follow_id" do
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

      # --- ユーザー自身のtags情報を検証 ---
      user_tags = json["user"]["tags"]
      expect(user_tags).to match_array([
        a_hash_including("name" => "TypeScript"),
        a_hash_including("name" => "Rails")
      ])

      # --- 各投稿のtags情報を検証 ---
      post_jsons = json["user"]["posts"]
      # post1（最古）にはRubyのみ
      ruby_post = post_jsons.find { |p| p["title"] == "Oldest Post" }
      expect(ruby_post["tags"].map { |t| t["name"] }).to match_array([ "Ruby" ])

      # post2にはReact, Other
      react_post = post_jsons.find { |p| p["title"] == "Middle Post" }
      expect(react_post["tags"].map { |t| t["name"] }).to match_array([ "React", "Other" ])

      # post3はタグなし
      newest_post = post_jsons.find { |p| p["title"] == "Newest Post" }
      expect(newest_post["tags"]).to eq([])

      # SNS情報（user_social_profiles）
      profiles = json["user"]["user_social_profiles"]
      expect(profiles.size).to eq(3)
      expect(profiles).to include(
        a_hash_including("provider" => "twitter", "url" => "https://x.com/testuser"),
        a_hash_including("provider" => "youtube", "url" => "https://youtube.com/testuser"),
        a_hash_including("provider" => "instagram", "url" => "https://instagram.com/testuser")
      )

    # --- followers: 新しい順(created_at desc) ---
    follower_names = json["user"]["followers"].map { |f| f["name"] }
    expect(follower_names).to eq([ "follower2", "follower1" ])
    # follow_idも含まれる
    expect(json["user"]["followers"].all? { |f| f["follow_id"].present? }).to be true

    # id,name,imageが正しく含まれる
    expect(json["user"]["followers"].first).to include(
      "id" => follower2.id,
      "name" => "follower2",
      "image" => follower2.image,
      "follow_id" => follower_rel2.id
    )

    # --- following: 新しい順(created_at desc) ---
    following_names = json["user"]["following"].map { |f| f["name"] }
    expect(following_names).to eq([ "following1", "following2" ])
    expect(json["user"]["following"].all? { |f| f["follow_id"].present? }).to be true
    expect(json["user"]["following"].first).to include(
      "id" => following1.id,
      "name" => "following1",
      "image" => following1.image,
      "follow_id" => following_rel1.id
    )
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
      expect(json["user"]["user_social_profiles"]).to eq([])
      expect(json["user"]["tags"]).to eq([])
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

    # 他のユーザー（権限チェックや重複名チェック用）
    let!(:other_user) { create(:user, name: "taken_name") }

    # 正常系：自分の情報を更新できる
    it "updates own user info successfully" do
      patch "/v1/users/#{user.id}", params: {
        user: {
          name: "new_name",
          bio: "new bio"
        }
      }, headers: jwt_auth_headers(user)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["user"]["id"]).to eq(user.id)
      expect(json["user"]["name"]).to eq("new_name")
      expect(json["user"]["bio"]).to eq("new bio")
      expect(json["user"]["tags"]).to eq([])
      expect(json["message"]).to eq("ユーザー情報を更新しました")
    end

    # 正常系：タグを新規付与できる
    it "adds tags to the user if tags param is present" do
      patch "/v1/users/#{user.id}", params: {
        user: {
          name: "tag_user",
          bio: "has tags",
          tags: [ "React", "Ruby" ]
        }
      }, headers: jwt_auth_headers(user)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      tag_names = json["user"]["tags"].map { |t| t["name"] }
      expect(tag_names).to match_array([ "React", "Ruby" ])
      # DBも反映
      expect(user.reload.tags.pluck(:name)).to match_array([ "React", "Ruby" ])
    end

    # 正常系：既存タグが全て外せる
    it "removes all tags if tags param is empty array" do
      user.tags << [ Tag.create!(name: "Tag1"), Tag.create!(name: "Tag2") ]
      expect(user.tags.count).to eq(2)

      patch "/v1/users/#{user.id}", params: {
        user: {
          name: "still_user",
          bio: "removed tags",
          tags: []
        }
      }, headers: jwt_auth_headers(user), as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["user"]["tags"]).to eq([])
      expect(user.reload.tags).to eq([])
    end

    # 異常系：存在しないユーザーIDを指定した場合
    it "returns 404 if user does not exist" do
      patch "/v1/users/00000000-0000-0000-0000-000000000000", params: {
        user: { name: "any", bio: "any" }
      }, headers: jwt_auth_headers(user)

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("ユーザーが見つかりません")
    end

    # 異常系：他人の情報は更新できない
    it "returns forbidden if trying to update another user" do
      patch "/v1/users/#{other_user.id}", params: {
        user: { name: "changed", bio: "changed" }
      }, headers: jwt_auth_headers(user)

      expect(response).to have_http_status(:forbidden)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("権限がありません")
    end

    # 異常系：ユーザー名が重複している場合
    it "returns error if name is already taken by another user" do
      patch "/v1/users/#{user.id}", params: {
        user: { name: "taken_name", bio: "any" }
      }, headers: jwt_auth_headers(user)

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("この名前は既に使用されています")
    end

    # 異常系：バリデーションエラー（例：名前が短すぎる場合）
    it "returns validation errors if params are invalid" do
      patch "/v1/users/#{user.id}", params: {
        user: { name: "a", bio: "b" }
      }, headers: jwt_auth_headers(user)

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

    # 無効なトークンのテスト
    it "returns unauthorized if token is invalid" do
      patch "/v1/users/#{user.id}", params: {
        user: { name: "hacker", bio: "hacker" }
      }, headers: { "Authorization" => "Bearer invalidtoken" }
      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("認証が必要です")
    end
  end

  describe "DELETE /v1/users/:id" do
    # テストユーザー・ヘッダー
    let!(:user) { create(:user, name: "delete_user") }

    # 他のユーザー（権限確認用）
    let!(:other_user) { create(:user, name: "otheruser") }

    # 正常系：自分のユーザーを削除できる
    it "deletes own user successfully" do
      expect {
        delete "/v1/users/#{user.id}", headers: jwt_auth_headers(user)
      }.to change(User, :count).by(-1)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["message"]).to eq("ユーザーを削除しました")
    end

    # 異常系：存在しないユーザーIDを指定した場合
    it "returns 404 if user does not exist" do
      expect {
        delete "/v1/users/00000000-0000-0000-0000-000000000000", headers: jwt_auth_headers(user)
      }.not_to change(User, :count)

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("ユーザーが見つかりません")
    end

    # 異常系：他人のユーザーを削除しようとした場合
    it "returns forbidden if trying to delete another user" do
      expect {
        delete "/v1/users/#{other_user.id}", headers: jwt_auth_headers(user)
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

    # 無効なトークンのテスト
    it "returns unauthorized if token is invalid" do
      delete "/v1/users/#{user.id}", headers: { "Authorization" => "Bearer invalidtoken" }
      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("認証が必要です")
    end
  end

  describe "POST /v1/users/:id/image" do
    let!(:user) { create(:user, name: "uploader") }
    let!(:other_user) { create(:user, name: "other") }

    # アップローダをスタブ（成功時のURLを固定）
    let(:stubbed_url) { "http://localhost:9000/user-avatars/users/#{user.id}/avatar.png" }

    before do
      allow(ImageUploader).to receive(:upload_user_avatar!).and_return(stubbed_url)
    end

    # 正常系：画像を2MB以下・許可された形式でアップロードできる
    it "returns 200 and updates user's image with returned URL" do
      file = build_uploaded_file(bytes: 256.kilobytes, content_type: "image/png", filename: "avatar.png")

      post "/v1/users/#{user.id}/image",
           params: { image: file },
           headers: jwt_auth_headers(user),
           as: :multipart

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["message"]).to eq("ユーザー画像を更新しました")
      expect(json["user"]["image"]).to eq(stubbed_url)
      expect(user.reload.image).to eq(stubbed_url)
      expect(ImageUploader).to have_received(:upload_user_avatar!).with(user_id: user.id, file: instance_of(ActionDispatch::Http::UploadedFile))
    end

    # 異常系：画像未指定
    it "returns 422 when image is not provided" do
      post "/v1/users/#{user.id}/image",
           params: {},
           headers: jwt_auth_headers(user),
           as: :multipart

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("画像ファイルが未指定です")
      expect(ImageUploader).not_to have_received(:upload_user_avatar!)
    end

    # 異常系：2MB超過でエラー
    it "returns 422 when file size exceeds 2MB" do
      big = 2.megabytes + 1
      file = build_uploaded_file(bytes: big, content_type: "image/jpeg", filename: "big.jpg")

      post "/v1/users/#{user.id}/image",
           params: { image: file },
           headers: jwt_auth_headers(user),
           as: :multipart

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("画像サイズは2MB以内にしてください")
      expect(ImageUploader).not_to have_received(:upload_user_avatar!)
    end

    # 異常系：未許可MIMEタイプ
    it "returns 422 when content type is not allowed" do
      file = build_uploaded_file(bytes: 10.kilobytes, content_type: "text/plain", filename: "note.txt")

      post "/v1/users/#{user.id}/image",
           params: { image: file },
           headers: jwt_auth_headers(user),
           as: :multipart

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("対応していない画像形式です")
      expect(ImageUploader).not_to have_received(:upload_user_avatar!)
    end

    # 異常系：他人の画像を更新しようとして403
    it "returns 403 when uploading image for another user" do
      file = build_uploaded_file(bytes: 50.kilobytes, content_type: "image/png", filename: "a.png")

      post "/v1/users/#{other_user.id}/image",
           params: { image: file },
           headers: jwt_auth_headers(user),
           as: :multipart

      expect(response).to have_http_status(:forbidden)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("権限がありません")
      expect(ImageUploader).not_to have_received(:upload_user_avatar!)
    end

    # 異常系：ユーザー未存在で404
    it "returns 404 when user not found" do
      file = build_uploaded_file(bytes: 50.kilobytes, content_type: "image/png", filename: "a.png")

      post "/v1/users/00000000-0000-0000-0000-000000000000/image",
           params: { image: file },
           headers: jwt_auth_headers(user),
           as: :multipart

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("ユーザーが見つかりません")
      expect(ImageUploader).not_to have_received(:upload_user_avatar!)
    end

    # 異常系：認証ヘッダーなしで401
    it "returns 401 when Authorization header is missing" do
      file = build_uploaded_file(bytes: 50.kilobytes, content_type: "image/png", filename: "a.png")

      post "/v1/users/#{user.id}/image",
           params: { image: file },
           as: :multipart

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("認証が必要です")
      expect(ImageUploader).not_to have_received(:upload_user_avatar!)
    end

    # 異常系：トークン不正で401
    it "returns 401 when token is invalid" do
      file = build_uploaded_file(bytes: 50.kilobytes, content_type: "image/png", filename: "a.png")

      post "/v1/users/#{user.id}/image",
           params: { image: file },
           headers: { "Authorization" => "Bearer invalidtoken" },
           as: :multipart

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("認証が必要です")
      expect(ImageUploader).not_to have_received(:upload_user_avatar!)
    end
  end
end
