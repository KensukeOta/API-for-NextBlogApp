class PostsController < ApplicationController
  before_action :find_current_user_by_header, only: [ :create ]

  def index
    posts = Post.includes(:user).order(created_at: :desc)

    render json: {
      posts: posts.as_json(
        only: [ :id, :title, :content, :user_id, :created_at, :updated_at ],
        include: { user: { only: [ :id, :name, :email, :image, :provider ] } }
      )
    }, status: :ok
  end

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
    params.expect(post: [ :title, :content ])
  end
end
