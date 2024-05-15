class UsersController < ApplicationController
  def create
    @user = User.find_or_create_by(user_params)                      
    if @user
      render json: @user, status: :created, location: @user
    else
      render json: { error: "ログインに失敗しました" }, status: :unprocessable_entity
    end
  end

  private

    def user_params
      params.require(:user).permit(:uid, :name, :email, :image, :provider)
    end
end
