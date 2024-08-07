class OauthController < ApplicationController
  def create
    # ユーザーが既に存在するかをメールアドレスとプロバイダーで検索
    @user = User.find_by(email: user_params[:email], provider: user_params[:provider])

    # 既存ユーザーが見つかった場合、ユーザーを返す
    if @user
      render json: @user, status: :ok
      return
    end
    
    # 新規ユーザーが見つからなかった場合、初期化
    @user = User.new(user_params)
    # OAuth認証の際、実際のパスワードは不要なのでランダムなパスワードを設定
    @user.password = SecureRandom.hex(10)
    # パスワード確認用に同じ値を設定
    @user.password_confirmation = @user.password

    if @user.save
      render json: @user, status: :created
    else
      render json: { error: @user.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  private

    def user_params
      params.permit(:uid, :name, :email, :image, :provider)
    end
end
