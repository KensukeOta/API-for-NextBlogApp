require 'rails_helper'

RSpec.describe "Posts", type: :request do
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
end
