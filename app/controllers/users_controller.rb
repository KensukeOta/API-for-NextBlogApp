class UsersController < ApplicationController
  def show_by_email
    @user = User.find_by(email: params[:email])
    if @user
      render json: @user, status: :ok
    else
      render json: { error: "User not found" }, status: :not_found
    end
  end
  
  def create
    @user = User.find_or_initialize_by(email: user_params[:email], provider: user_params[:provider])
    
    if @user.persisted?
      render json: { error: "ユーザーは既に存在します" }, status: :unprocessable_entity
      return
    end

    # パスワードが提供されている場合のみ設定します
    if user_params[:password].present?
      @user.password = user_params[:password]
      @user.password_confirmation = user_params[:password_confirmation]
    end

    @user.assign_attributes(user_params.except(:password, :password_confirmation))
    
    if @user.save
      render json: @user, status: :created, location: @user
    else
      render json: { error: @user.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  def login
    Rails.logger.debug "Login params: #{login_params.inspect}"
    user = User.find_by(email: login_params[:email])
    if user && user.authenticate(login_params[:password])
      render json: user, status: :ok
    else
      render json: { error: 'Invalid email or password' }, status: :unauthorized
    end
  end

  private

    def user_params
      params.permit(:uid, :name, :email, :image, :provider, :password, :password_confirmation)
    end

    def login_params
      params.permit(:email, :password)
    end
end
