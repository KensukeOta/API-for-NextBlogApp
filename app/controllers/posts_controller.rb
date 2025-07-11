class PostsController < ApplicationController
  before_action :find_current_user_by_header, only: [ :create, :update, :destroy ]
  before_action :set_post, only: [ :update, :destroy ]

  def index
    # クエリパラメータ q 取得（例: /v1/posts?q=テスト）
    query = params[:q]
    # ページ番号（1始まり。なければ1）
    page = params[:page].to_i > 0 ? params[:page].to_i : 1
    # 1ページあたり件数（なければ10）
    per_page = params[:per].to_i > 0 ? params[:per].to_i : 10

    if query.present?
      # タイトル・ユーザー名・タグ名で部分一致検索
      # クエリにマッチする記事IDだけ取得
      post_ids = Post.joins(:user)
                     .left_joins(:tags)
                     .where("posts.title ILIKE :q OR users.name ILIKE :q OR tags.name ILIKE :q", q: "%#{query}%")
                     .distinct
                     .pluck(:id)

      posts = Post.includes(:user, :likes, :tags).where(id: post_ids)
    else
      posts = Post.includes(:user, :likes, :tags)
    end

    total_count = posts.count

    posts = posts.order(created_at: :desc).limit(per_page).offset((page - 1) * per_page)

    render json: {
      posts: posts.as_json(
        only: [ :id, :title, :content, :user_id, :created_at, :updated_at ],
        include: {
          user: { only: [ :id, :name, :email, :image, :provider ] },
          likes: {},
          tags: { only: [ :id, :name ] }
        }
      ),
      total_count: total_count
    }, status: :ok
  end

  def show
    post = Post.includes(:user, :likes).find_by(id: params[:id])

    if post
      render json: {
        post: post.as_json(
          only: [ :id, :title, :content, :user_id, :created_at, :updated_at ],
          include: {
            user: { only: [ :id, :name, :email, :image, :provider ] },
            likes: {},
            tags: { only: [ :id, :name ] }
          }
        )
      }, status: :ok
    else
      render json: { error: "記事が見つかりません" }, status: :not_found
    end
  end

  def create
    post = current_user.posts.build(post_params.except(:tags))

    if post.save
      # タグの登録
      if post_params.key?(:tags)
        if post_params[:tags].present?
          tags = post_params[:tags].map { |name| Tag.find_or_create_by!(name: name) }
          post.tags = tags
        else
          post.tags = []
        end
      end

      render json: {
        post: post.as_json(
          only: [ :id, :title, :content, :user_id, :created_at, :updated_at ],
          include: {
            user: { only: [ :id, :name, :email, :image, :provider ] },
            tags: { only: [ :id, :name ] }
          }
        )
      }, status: :created
    else
      render json: { errors: post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    unless @post
      render json: { error: "記事が見つかりません" }, status: :not_found
      return
    end

    # 他人の記事を更新しようとした場合
    unless @post.user_id == current_user.id
      render json: { error: "権限がありません" }, status: :forbidden
      return
    end

    if @post.update(post_params.except(:tags))
      # タグが渡っていれば更新する
      if post_params.key?(:tags)
        if post_params[:tags].present?
          tags = post_params[:tags].map { |name| Tag.find_or_create_by!(name: name) }
          @post.tags = tags
        else
          # 空配列ならタグを全解除
          @post.tags = []
        end
      end

      render json: {
        post: @post.as_json(
          only: [ :id, :title, :content, :user_id, :created_at, :updated_at ],
          include: {
            user: { only: [ :id, :name, :email, :image, :provider ] },
            tags: { only: [ :id, :name ] }
          }
        )
      }, status: :ok
    else
      render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    unless @post
      render json: { error: "記事が見つかりません" }, status: :not_found
      return
    end

    unless @post.user_id == current_user.id
      render json: { error: "権限がありません" }, status: :forbidden
      return
    end

    if @post.destroy
      render json: { message: "記事を削除しました" }, status: :ok
    else
      render json: { error: "記事の削除に失敗しました" }, status: :unprocessable_entity
    end
  end

  private

    def set_post
      @post = Post.find_by(id: params[:id])
    end

    def post_params
      params.expect(post: [ :title, :content, tags: [] ])
    end
end
