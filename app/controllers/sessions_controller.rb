class SessionsController < ApplicationController
  def create
    user = User.find_by(email: login_params[:email], provider: login_params[:provider])
    if user && user.authenticate(login_params[:password])
      token = JsonWebToken.encode(user_id: user.id)
      render json: {
        user: user.as_json(only: [ :id, :name, :email, :provider, :image ]).merge(accessToken: token)
      }, status: :ok
    else
      render json: { error: "ログインに失敗しました" }, status: :unauthorized
    end
  end

  private

    def login_params
      params.expect(user: [ :email, :password, :provider ])
    end
end
