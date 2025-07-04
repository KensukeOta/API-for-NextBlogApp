class UsersController < ApplicationController
  before_action :find_current_user_by_header, only: [ :update, :destroy ]

  def show_by_name
    user = User.includes(:posts, :likes).find_by(name: params[:name])
    if user
      # postsを新しい順にソートしてから as_json で連携
      posts = user.posts.order(created_at: :desc)
      # いいねした新しい順に取得
      liked_posts = user.liked_posts
                        .select("posts.*, likes.created_at as liked_at")
                        .order("likes.created_at DESC")

      render json: {
        user: user.as_json(
          only: [ :id, :name, :email, :image, :provider, :bio ],
          include: {
            posts: {
              only: [ :id, :title, :content, :created_at, :updated_at ],
              include: {
                user: {
                  only: [ :id, :name, :email, :image, :provider ]
                }
              }
            },
            user_social_profiles: {
              only: [ :id, :provider, :url ]
            }
          }
        ).merge("posts" => posts.as_json(
          only: [ :id, :title, :content, :created_at, :updated_at ],
          include: {
            user: {
              only: [ :id, :name, :email, :image, :provider ]
            },
            likes: {}
          }
        ),
        "liked_posts" => liked_posts.as_json(
            only: [ :id, :title, :content, :created_at, :updated_at ],
            methods: [ :liked_at ],
            include: {
              user: {
                only: [ :id, :name, :email, :image, :provider ]
              },
              likes: {}
            }
          )
        )
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

  def update
    user = User.find_by(id: params[:id])
    unless user
      return render json: { error: "ユーザーが見つかりません" }, status: :not_found
    end

    unless user.id == current_user.id
      return render json: { error: "権限がありません" }, status: :forbidden
    end

    # ユーザー名が変更されていて、かつその名前が他のユーザーで既に使われていた場合
    if user_params[:name].present? &&
       user_params[:name] != user.name &&
       User.exists?(name: user_params[:name])
      return render json: { error: "この名前は既に使用されています" }, status: :unprocessable_entity
    end

    if user.update(user_params)
      render json: {
        user: user.as_json(only: [ :id, :name, :email, :provider, :image, :bio ]),
        message: "ユーザー情報を更新しました"
      }, status: :ok
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    user = User.find_by(id: params[:id])
    unless user
      return render json: { error: "ユーザーが見つかりません" }, status: :not_found
    end

    unless user.id == current_user.id
      return render json: { error: "権限がありません" }, status: :forbidden
    end

    if user.destroy
      render json: { message: "ユーザーを削除しました" }, status: :ok
    else
      render json: { error: "ユーザーの削除に失敗しました" }, status: :unprocessable_entity
    end
  end

  private

    def user_params
      params.expect(user: [ :name, :email, :provider, :password, :password_confirmation, :image, :bio ])
    end
end
