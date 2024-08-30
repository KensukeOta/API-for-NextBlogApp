class PostsController < ApplicationController
  def index
    # ベースクエリを作成
    @posts = Post.includes(:user, :likes, :tags).order(created_at: :desc)
    
    # クエリパラメータに基づいてフィルタリング
    if query_params[:query].present?
      query = "%#{query_params[:query]}%"
      @posts = @posts.left_outer_joins(:user, :tags)
                     .where('title LIKE :query OR users.name LIKE :query OR tags.name LIKE :query', query: query)
                     .distinct
    end

    # LIMITとOFFSETを追加
    @posts = @posts.limit(params[:limit]) if params[:limit].present?
    @posts = @posts.offset(params[:offset]) if params[:offset].present?

    render json: { allPosts: @posts }, status: :ok, include: { user: {}, likes: { include: :user }, tags: {} }
  end

  def show
    @post = Post.includes(:user, :likes, :tags).find(params[:id])

    render json: { post: @post }, status: :ok, include: { user: {}, likes: { include: :user }, tags: {} }
  end
  
  def create
    @post = Post.new(post_params)

    if @post.save
      # タグの処理
      if params[:tags].present?
        process_tags(@post, params[:tags])
      end
      render json: @post, status: :created, location: @post
    else
      render json: @post.errors, status: :unprocessable_entity
    end
  end

  def update
    @post = Post.find(params[:id])
    
    if @post.update(post_params)
      # タグの処理
      if params[:tags].present?
        @post.tags.clear # 既存のタグをクリア
        process_tags(@post, params[:tags])
      end
      render json: @post
    else
      render json: @post.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @post = Post.find(params[:id])

    @post.destroy
  end

  # フォローしているユーザーの投稿を新しい順に取得するアクション
  def timeline
    user = User.find(params[:id])
    # フォローしているユーザーのIDを取得
    following_ids = user.followings.pluck(:id)
    # フォローしているユーザーの投稿を取得し、新しい順に並べる
    posts = Post.where(user_id: following_ids).order(created_at: :desc)

    render json: posts.as_json(
      include: {
        user: {},
        tags: {},
        likes: {},
      }
    ), status: :ok
  end

  private

    def post_params
      params.require(:post).permit(:title, :body, :user_id)
    end

    def query_params
      params.permit(:query)
    end

    def process_tags(post, tags)
      tags.each do |tag_name|
        next if tag_name.strip.blank?
        
        tag = Tag.find_or_create_by(name: tag_name.strip)
        post.tags << tag unless post.tags.include?(tag)
      end
    end
end
