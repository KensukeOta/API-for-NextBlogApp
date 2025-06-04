class PostsController < ApplicationController
  before_action :find_current_user_by_header, only: [ :create, :update, :destroy ]

  def index
    posts = Post.includes(:user).order(created_at: :desc)

    render json: {
      posts: posts.as_json(
        only: [ :id, :title, :content, :user_id, :created_at, :updated_at ],
        include: { user: { only: [ :id, :name, :email, :image, :provider ] } }
      )
    }, status: :ok
  end

  def show
    post = Post.includes(:user).find_by(id: params[:id])

    if post
      render json: {
        post: post.as_json(
          only: [ :id, :title, :content, :user_id, :created_at, :updated_at ],
          include: { user: { only: [ :id, :name, :email, :image, :provider ] } }
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
    post = Post.find_by(id: params[:id])

    if post.nil?
      render json: { error: "記事が見つかりません" }, status: :not_found
      return
    end

    # 他人の記事を更新しようとした場合
    unless post.user_id == current_user.id
      render json: { error: "権限がありません" }, status: :forbidden
      return
    end

    if post.update(post_params)
      render json: {
        post: post.as_json(
          only: [ :id, :title, :content, :user_id, :created_at, :updated_at ],
          include: { user: { only: [ :id, :name, :email, :image, :provider ] } }
        )
      }, status: :ok
    else
      render json: { errors: post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    post = Post.find_by(id: params[:id])

    if post.nil?
      render json: { error: "記事が見つかりません" }, status: :not_found
      return
    end

    unless post.user_id == current_user.id
      render json: { error: "権限がありません" }, status: :forbidden
      return
    end

    if post.destroy
      render json: { message: "記事を削除しました" }, status: :ok
    else
      render json: { error: "記事の削除に失敗しました" }, status: :unprocessable_entity
    end
  end

  private

    def post_params
      params.expect(post: [ :title, :content ])
    end
end
