class LikesController < ApplicationController
  before_action :authorize_request

  def create
    post = Post.find_by(id: like_params[:post_id])
    unless post
      return render json: { error: "記事が見つかりません" }, status: :not_found
    end

    like = Like.find_or_initialize_by(user: current_user, post: post)
    if like.persisted?
      return render json: { message: "すでにいいねしています" }, status: :ok
    end

    if like.save
      render json: { message: "いいねしました", like: like }, status: :created
    else
      render json: { errors: like.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    like = Like.find_by(id: params[:id], user: current_user)
    unless like
      return render json: { error: "いいねが見つかりません" }, status: :not_found
    end

    like.destroy
    render json: { message: "いいねを解除しました" }, status: :ok
  end

  private

    def like_params
      params.expect(like: [ :post_id ])
    end
end
