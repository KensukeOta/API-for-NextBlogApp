class UsersController < ApplicationController
  def create
    # email+providerの組み合わせの存在チェック
    if User.find_by(email: user_params[:email], provider: user_params[:provider])
      render json: { error: "ユーザーは既に存在します" }, status: :unprocessable_entity
      return
    end

    # nameの存在チェック
    if User.find_by(name: user_params[:name])
      render json: { error: "この名前は既に使用されています" }, status: :unprocessable_entity
      return
    end

    user = User.new(user_params)
    if user.save
      render json: { user: user.as_json(except: [ :password_digest ]), message: "ユーザー登録が完了しました" }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

    def user_params
      params.expect(user: [ :name, :email, :provider, :password, :password_confirmation, :image ])
    end
end
