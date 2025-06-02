class PostsController < ApplicationController
  before_action :find_current_user_by_header, only: [ :create ]

  def create
    post = current_user.posts.build(post_params)

    if post.save
      render json: { post: post.as_json(only: [ :id, :title, :content, :user_id, :created_at, :updated_at ]) }, status: :created
    else
      render json: { errors: post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def post_params
    params.require(:post).permit(:title, :content)
  end
end
