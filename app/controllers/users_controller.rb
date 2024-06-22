class UsersController < ApplicationController
  def show_by_email_and_provider
    @user = User.includes(:posts).find_by(email: user_params[:email], provider: user_params[:provider])
    if @user
      @posts = @user.posts.order(created_at: :desc)
      render json: @user.as_json.merge(posts: @posts), status: :ok
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

  private

    def user_params
      params.permit(:uid, :name, :email, :image, :provider, :password, :password_confirmation)
    end
end
