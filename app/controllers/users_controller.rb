class UsersController < ApplicationController
  before_action :authorize_request, only: [ :update, :destroy, :image ]
  before_action :set_user, only: [ :update, :destroy, :image ]

  def show_by_name
    user = User.includes(:posts, :likes).find_by(name: params[:name])
    if user
      # postsを新しい順にソートしてから as_json で連携
      posts = user.posts.order(created_at: :desc)
      # いいねした新しい順に取得
      liked_posts = user.liked_posts
                        .select("posts.*, likes.created_at as liked_at")
                        .order("likes.created_at DESC")

      followers = user.follower_relationships
                      .includes(:follower)
                      .order(created_at: :desc)
                      .map do |rel|
        {
          id: rel.follower.id,
          name: rel.follower.name,
          image: rel.follower.image,
          follow_id: rel.id
        }
      end

      following = user.following_relationships
                      .includes(:followed)
                      .order(created_at: :desc)
                      .map do |rel|
        {
          id: rel.followed.id,
          name: rel.followed.name,
          image: rel.followed.image,
          follow_id: rel.id
        }
      end

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
            },
            tags: {
              only: [ :id, :name ]
            }
          }
        ).merge("posts" => posts.as_json(
          only: [ :id, :title, :content, :created_at, :updated_at ],
          include: {
            user: {
              only: [ :id, :name, :email, :image, :provider ]
            },
            likes: {},
            tags: {
              only: [ :id, :name ]
            }
          }
        ),
        "liked_posts" => liked_posts.as_json(
            only: [ :id, :title, :content, :created_at, :updated_at ],
            methods: [ :liked_at ],
            include: {
              user: {
                only: [ :id, :name, :email, :image, :provider ]
              },
              likes: {},
              tags: {
                only: [ :id, :name ]
              }
            }
        ),
        "followers" => followers,
        "following" => following
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
    unless @user
      return render json: { error: "ユーザーが見つかりません" }, status: :not_found
    end

    unless @user.id == current_user.id
      return render json: { error: "権限がありません" }, status: :forbidden
    end

    # ユーザー名が変更されていて、かつその名前が他のユーザーで既に使われていた場合
    if user_params[:name].present? &&
       user_params[:name] != @user.name &&
       User.exists?(name: user_params[:name])
      return render json: { error: "この名前は既に使用されています" }, status: :unprocessable_entity
    end

    if @user.update(user_params.except(:tags))
      # タグが渡っていれば更新する
      if user_params.key?(:tags)
        if user_params[:tags].present?
          tags = user_params[:tags].map { |name| Tag.find_or_create_by!(name: name) }
          @user.tags = tags
        else
          # 空配列ならタグを全解除
          @user.tags = []
        end
      end

      render json: {
        user: @user.as_json(
          only: [ :id, :name, :email, :provider, :image, :bio ],
          include: { tags: { only: [ :id, :name ] } }
        ),
        message: "ユーザー情報を更新しました"
      }, status: :ok
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    unless @user
      return render json: { error: "ユーザーが見つかりません" }, status: :not_found
    end

    unless @user.id == current_user.id
      return render json: { error: "権限がありません" }, status: :forbidden
    end

    if @user.destroy
      render json: { message: "ユーザーを削除しました" }, status: :ok
    else
      render json: { error: "ユーザーの削除に失敗しました" }, status: :unprocessable_entity
    end
  end

  def image
    unless @user
      return render json: { error: "ユーザーが見つかりません" }, status: :not_found
    end

    unless @user.id == current_user.id
      return render json: { error: "権限がありません" }, status: :forbidden
    end

    file = params[:image]
    unless file&.respond_to?(:original_filename)
      return render json: { error: "画像ファイルが未指定です" }, status: :unprocessable_entity
    end

    max_size = 2.megabytes
    if file.size > max_size
      return render json: { error: "画像サイズは2MB以内にしてください" }, status: :unprocessable_entity
    end

    # （任意）基本的なバリデーション例
    allowed = %w[image/jpeg image/png image/webp image/gif]
    unless allowed.include?(file.content_type)
      return render json: { error: "対応していない画像形式です" }, status: :unprocessable_entity
    end

    url = ImageUploader.upload_user_avatar!(user_id: @user.id, file: file)

    if @user.update(image: url)
      render json: {
        user: @user.as_json(only: [ :id, :name, :email, :provider, :image, :bio ]),
        message: "ユーザー画像を更新しました"
      }, status: :ok
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

    def set_user
      @user = User.find_by(id: params[:id])
    end

    def user_params
      params.expect(user: [ :name, :email, :provider, :password, :password_confirmation, :image, :bio, tags: [] ])
    end
end
