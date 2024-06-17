require 'rails_helper'

RSpec.describe "UsersApis", type: :request do
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
