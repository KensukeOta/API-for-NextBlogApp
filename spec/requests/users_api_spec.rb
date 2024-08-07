require 'rails_helper'

RSpec.describe "UsersApis", type: :request do
  describe "GET /v1/users" do
    before do
      FactoryBot.create(:user, name: "hoge", email: "hoge@example.com", provider: "google")
      FactoryBot.create(:user, name: "fuga", email: "fuga@example.com", provider: "credentials")
    end

    # 200レスポンスを返すこと
    it "returns a 200 response" do
      get users_path
      expect(response).to have_http_status(:success)
    end

    # ユーザーを全件返すこと
    it "returns all users" do
      get users_path
      json = JSON.parse(response.body)
      expect(json.length).to eq 2
    end

    # 渡されてきた名前に合致するユーザーを返すこと
    it "return the user that matches the given name" do
      get "/v1/users?name=hoge"
      json = JSON.parse(response.body)
      expect(json["name"]).to eq "hoge"
      expect(response).to have_http_status(:success)
    end

    # 渡されてきたメールアドレスとプロバイダーに合致するユーザーを返すこと
    it "return the user that matches the given email address and provider" do
      get "/v1/users?email=hoge@example.com&provider=google"
      json = JSON.parse(response.body)
      expect(json["name"]).to eq "hoge"
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /v1/users" do
    # ユーザーを作成できること
    it "creates a user" do
      user_attributes = FactoryBot.attributes_for(:user)
      
      expect {
        post users_path, params: user_attributes
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
    end
  end
end
