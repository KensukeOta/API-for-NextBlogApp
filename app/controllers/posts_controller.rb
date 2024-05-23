class PostsController < ApplicationController
  def index
    @posts = Post.includes(:user).order(created_at: :desc)
    
    render json: { allPosts: @posts }, status: :ok, include: :user
  end

  def show
    @post = Post.includes(:user).find(params[:id])

    render json: { post: @post }, status: :ok, include: :user
  end
  
  def create
    @post = Post.new(post_params)

    if @post.save
      render json: @post, status: :created, location: @post
    else
      render json: @post.errors, status: :unprocessable_entity
    end
  end

  def update
    @post = Post.find(params[:id])
    
    if @post.update(post_params)
      render json: @post
    else
      render json: @post.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @post = Post.find(params[:id])

    @post.destroy
  end

  private

    def post_params
      params.require(:post).permit(:title, :body, :user_id)
    end
end
