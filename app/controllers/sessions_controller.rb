class SessionsController < ApplicationController
  def create
    user = User.find_by(email: login_params[:email], provider: login_params[:provider])
    if user && user.authenticate(login_params[:password])
      render json: user, status: :ok
    else
      render json: { error: 'Invalid email or password' }, status: :unauthorized
    end
  end

  private

    def login_params
      params.permit(:email, :password, :provider)
    end
end
