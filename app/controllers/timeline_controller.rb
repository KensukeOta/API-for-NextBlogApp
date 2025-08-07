class TimelineController < ApplicationController
  before_action :authorize_request

  # GET /v1/timeline
  def index
    # フォローしているユーザー＋自分自身のID一覧
    user_ids = current_user.following.pluck(:id) + [ current_user.id ]

    posts = Post
      .includes(:user, :likes, :tags)
      .where(user_id: user_ids)
      .order(created_at: :desc)

    render json: {
      posts: posts.as_json(
        only: [ :id, :title, :content, :user_id, :created_at, :updated_at ],
        include: {
          user: { only: [ :id, :name, :email, :image, :provider ] },
          likes: {},
          tags: { only: [ :id, :name ] }
        }
      )
    }, status: :ok
  end
end
