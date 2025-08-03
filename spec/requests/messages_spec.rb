require 'rails_helper'

RSpec.describe "Messages", type: :request do
  # JWTヘッダー発行ヘルパー
  def jwt_auth_headers(user)
    token = JsonWebToken.encode(user_id: user.id)
    { "Authorization" => "Bearer #{token}" }
  end

  # ==============================
  # GET /v1/messages（会話一覧・2者間メッセージ一覧）
  # ==============================
  describe "GET /v1/messages" do
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }
    let!(:user3) { create(:user) }

    let!(:message1) { create(:message, from_user: user1, to_user: user2, content: "Hi user2!", created_at: 2.hours.ago) }
    let!(:message2) { create(:message, from_user: user2, to_user: user1, content: "Hello user1!", created_at: 1.hour.ago) }
    let!(:message3) { create(:message, from_user: user1, to_user: user3, content: "Hi user3!", created_at: 3.hours.ago) }

    # 2者間メッセージ取得
    # user1がuser2とのメッセージ一覧を取得できる
    it "returns messages between the current user and the partner user in ascending order" do
      get "/v1/messages", params: { with_user_id: user2.id }, headers: jwt_auth_headers(user1)
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to have_key("partner")
      expect(json).to have_key("messages")
      expect(json["partner"]["id"]).to eq(user2.id)
      expect(json["messages"].size).to eq(2)
      expect(json["messages"][0]["content"]).to eq("Hi user2!")
      expect(json["messages"][1]["content"]).to eq("Hello user1!")
    end

    # 存在しないユーザーとの会話取得
    it "returns 404 if the partner user does not exist" do
      get "/v1/messages", params: { with_user_id: "00000000-0000-0000-0000-000000000000" }, headers: jwt_auth_headers(user1)
      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("相手ユーザーが存在しません")
    end

    # 認証ヘッダー無し
    it "returns 401 if Authorization header is missing" do
      get "/v1/messages", params: { with_user_id: user2.id }
      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("認証が必要です")
    end

    # 会話一覧（全ての会話ごとの最新メッセージ）
    it "returns conversations with the latest message and unread count" do
      # user1→user2, user1→user3 それぞれ会話がある
      get "/v1/messages", headers: jwt_auth_headers(user1)
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to have_key("conversations")
      expect(json["conversations"]).to be_a(Array)
      # 会話数
      expect(json["conversations"].length).to eq(2)
      partners = json["conversations"].map { |c| c["partner"]["id"] }
      expect(partners).to contain_exactly(user2.id, user3.id)
      # 最新メッセージの内容が入っていること
      user2_convo = json["conversations"].find { |c| c["partner"]["id"] == user2.id }
      expect(user2_convo["last_message"]["content"]).to eq("Hello user1!")
    end
  end

  # ==============================
  # POST /v1/messages
  # ==============================
  describe "POST /v1/messages" do
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }
    let(:valid_params) {
      {
        message: {
          to_user_id: user2.id,
          content: "Hello from user1"
        }
      }
    }
    let(:invalid_params) {
      {
        message: {
          to_user_id: user2.id,
          content: "" # 空なのでバリデーションエラー
        }
      }
    }

    # 正常系
    # 有効なパラメータでメッセージを作成できる
    it "creates a message with valid params" do
      expect {
        post "/v1/messages", params: valid_params, headers: jwt_auth_headers(user1)
      }.to change(Message, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["from_user_id"]).to eq(user1.id)
      expect(json["to_user_id"]).to eq(user2.id)
      expect(json["content"]).to eq("Hello from user1")
      expect(json["read"]).to eq(false)
    end

    # 異常系
    # 自分宛てNG
    it "returns 403 if user tries to send message to self" do
      post "/v1/messages", params: { message: { to_user_id: user1.id, content: "Self message" } }, headers: jwt_auth_headers(user1)
      expect(response).to have_http_status(:forbidden)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("自分宛にはメッセージを送れません")
    end

    # 宛先ユーザーが存在しない
    it "returns 404 if recipient user does not exist" do
      post "/v1/messages", params: { message: { to_user_id: "00000000-0000-0000-0000-000000000000", content: "Test" } }, headers: jwt_auth_headers(user1)
      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("宛先ユーザーが存在しません")
    end

    # バリデーションエラー
    it "returns 422 if content is invalid" do
      post "/v1/messages", params: invalid_params, headers: jwt_auth_headers(user1)
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to include("Content can't be blank")
    end

    # 認証無し
    it "returns 401 if Authorization header is missing" do
      post "/v1/messages", params: valid_params
      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("認証が必要です")
    end
  end

  # ==============================
  # PATCH /v1/messages/:id/read
  # ==============================
  describe "PATCH /v1/messages/:id/read" do
    let!(:from_user) { create(:user) }
    let!(:to_user)   { create(:user) }
    let!(:message)   { create(:message, from_user: from_user, to_user: to_user, content: "Please read", read: false) }

    # 正常系: 受信者だけが既読にできる
    it "marks the message as read if current_user is recipient" do
      patch "/v1/messages/#{message.id}/read", headers: jwt_auth_headers(to_user)
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["message"]).to eq("既読にしました")
      expect(message.reload.read).to eq(true)
    end

    # 異常系: 送信者は既読にできない
    it "returns 404 if current_user is not recipient" do
      patch "/v1/messages/#{message.id}/read", headers: jwt_auth_headers(from_user)
      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("メッセージが見つかりません")
      expect(message.reload.read).to eq(false)
    end

    # 存在しないメッセージID
    it "returns 404 if message does not exist" do
      patch "/v1/messages/99999999/read", headers: jwt_auth_headers(to_user)
      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("メッセージが見つかりません")
    end

    # 認証無し
    it "returns 401 if Authorization header is missing" do
      patch "/v1/messages/#{message.id}/read"
      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("認証が必要です")
    end
  end
end
