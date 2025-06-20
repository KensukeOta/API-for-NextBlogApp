class UsersController < ApplicationController
  def show_by_name
    user = User.includes(:posts).find_by(name: params[:name])
    if user
      # postsを新しい順にソートしてから as_json で連携
      posts = user.posts.order(created_at: :desc)

      render json: {
        user: user.as_json(
          only: [ :id, :name, :email, :image, :provider ],
          include: {
            posts: {
              only: [ :id, :title, :content, :created_at, :updated_at ],
              include: {
                user: {
                  only: [ :id, :name, :email, :image, :provider ]
                }
              }
            }
          }
        ).merge("posts" => posts.as_json(
          only: [ :id, :title, :content, :created_at, :updated_at ],
          include: {
            user: {
              only: [ :id, :name, :email, :image, :provider ]
            }
          }
        ))
      }, status: :ok
    else
      render json: { error: "ユーザーが見つかりません" }, status: :not_found
    end
  end

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
      render json: {
        user: user.as_json(only: [ :id, :name, :email, :provider, :image ]),
        message: "ユーザー登録が完了しました"
      }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

    def user_params
      params.expect(user: [ :name, :email, :provider, :password, :password_confirmation, :image ])
    end
end
