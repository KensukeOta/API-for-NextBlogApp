require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  describe "POST /v1/sessions" do
    before do
      FactoryBot.create(:user, email: "hoge@example.com", password: "hogefuga", provider: "google")
    end
    
    # 認証が通ること
    it "is valid if authentication is successful" do
      post sessions_path, params: {
        email: "hoge@example.com", password: "hogefuga", provider: "google"
      }
      expect(response).to have_http_status(:success)
    end
  end
end
