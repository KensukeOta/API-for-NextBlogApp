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

    posts = Post.includes(:user, :likes)
    if query.present?
      # タイトルまたは著者名（user.name）で部分一致検索
      posts = posts.references(:user).where(
        "posts.title ILIKE :q OR users.name ILIKE :q", q: "%#{query}%"
      )
    end

    total_count = posts.count

    posts = posts.order(created_at: :desc).limit(per_page).offset((page - 1) * per_page)

    render json: {
      posts: posts.as_json(
        only: [ :id, :title, :content, :user_id, :created_at, :updated_at ],
        include: { user: { only: [ :id, :name, :email, :image, :provider ] }, likes: {} }
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
          include: { user: { only: [ :id, :name, :email, :image, :provider ] }, likes: {} }
        )
      }, status: :ok
    else
      render json: { error: "記事が見つかりません" }, status: :not_found
    end
  end

  def create
    post = current_user.posts.build(post_params)

    if post.save
      render json: { post: post.as_json(only: [ :id, :title, :content, :user_id, :created_at, :updated_at ]) }, status: :created
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

    if @post.update(post_params)
      render json: {
        post: @post.as_json(
          only: [ :id, :title, :content, :user_id, :created_at, :updated_at ],
          include: { user: { only: [ :id, :name, :email, :image, :provider ] } }
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
      params.expect(post: [ :title, :content ])
    end
end
