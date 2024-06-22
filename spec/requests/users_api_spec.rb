require 'rails_helper'

RSpec.describe "UsersApis", type: :request do
  describe "POST /v1/api/users/show_by_email_and_provider" do
    before do
      FactoryBot.create(:user, name: "hoge", email: "hoge@example.com", provider: "google")
    end

    # 200レスポンスを返すこと
    it "returns a 200 response" do
      get "/v1/api/users/show_by_email_and_provider?email=hoge@example.com&provider=google"
      expect(response).to have_http_status(:success)
    end

    # 渡されてきたメールアドレスとプロバイダーに合致するユーザーを返すこと
    it "return the user that matches the given email address and provider" do
      get "/v1/api/users/show_by_email_and_provider?email=hoge@example.com&provider=google"
      json = JSON.parse(response.body)
      expect(json["name"]).to eq "hoge"
    end
  end
  
  describe "POST /v1/api/users" do
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
