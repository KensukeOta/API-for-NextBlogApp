class PostsController < ApplicationController
  def index
    @posts = Post.order(created_at: :desc).includes(:user)
    
    render json: { allPosts: @posts }, include: :user
  end
  
  def create
    @post = Post.new(post_params)

    if @post.save
      render json: @post, status: :created, location: @post
    else
      render json: @post.errors, status: :unprocessable_entity
    end
  end

  private

    def post_params
      params.require(:post).permit(:title, :body, :user_id)
    end
end
