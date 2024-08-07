require 'rails_helper'

RSpec.describe "Oauths", type: :request do
  describe "POST /v1/auth/:provider/callback" do
    # OAuth認証ユーザーを作成できること
    it "creates a oauth user" do
      oauth_attributes = FactoryBot.attributes_for(:oauth_user)
      expect {
        post "/v1/auth/#{oauth_attributes[:provider]}/callback", params: oauth_attributes
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
    end
  end
end
