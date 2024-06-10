class OauthController < ApplicationController
  def callback
    @user = User.find_or_create_by(user_params)
    if @user
      render json: @user, status: :created
    else
      render json: { error: "ログインに失敗しました" }, status: :unprocessable_entity
    end
  end

  private

    def user_params
      params.permit(:uid, :name, :email, :image, :provider)
    end
end
