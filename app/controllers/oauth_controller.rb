class OauthController < ApplicationController
  def callback
    # ユーザーが既に存在するかをメールアドレスとプロバイダーで検索し、存在しない場合は新規ユーザーを初期化
    @user = User.find_or_initialize_by(email: user_params[:email], provider: user_params[:provider])
    
    # ユーザーがまだ保存されていない場合（新規ユーザーの場合）
    unless @user.persisted?
      # ユーザーの属性をパラメータから設定
      @user.assign_attributes(user_params)
      # OAuth認証の際、実際のパスワードは不要なのでランダムなパスワードを設定
      @user.password = SecureRandom.hex(10)  # バーチャルなパスワードを設定
      # パスワード確認用に同じ値を設定
      @user.password_confirmation = @user.password
    end

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
