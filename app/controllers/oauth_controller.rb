class OauthController < ApplicationController
  def create
    # ユーザーが既に存在するかをメールアドレスとプロバイダーで検索
    user = User.find_by(email: user_params[:email], provider: user_params[:provider])

    # 既存ユーザーが見つかった場合、ユーザーを返す
    if user
      render json: {
        user: user.as_json(only: [ :id, :name, :email, :provider, :image ])
      }, status: :ok
      return
    end

    name = user_params[:name]
    original_name = name

    # 重複していたらランダムな文字列（例: 6文字の英数字）を付与してユニーク化
    while User.exists?(name: name)
      suffix = SecureRandom.alphanumeric(6)  # 例: "xPz3Qa"
      name = "#{original_name}_#{suffix}"
      # nameカラムが最大32文字なのでオーバーしないように調整
      max_base_length = 32 - 1 - 6  # "_xxxxxx"
      trimmed_name = original_name[0, max_base_length]
      name = "#{trimmed_name}_#{suffix}"
    end

    # 新規ユーザーが見つからなかった場合、初期化
    user = User.new(user_params.merge(name: name))
    # OAuth認証の際、実際のパスワードは不要なのでランダムなパスワードを設定
    user.password = SecureRandom.hex(10)
    # パスワード確認用に同じ値を設定
    user.password_confirmation = user.password

    if user.save
      render json: {
        user: user.as_json(only: [ :id, :name, :email, :provider, :image ])
      }, status: :created
    else
      render json: { error: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

    def user_params
      params.expect(user: [ :name, :email, :provider, :image ])
    end
end
