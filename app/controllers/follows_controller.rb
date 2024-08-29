class FollowsController < ApplicationController
  # フォローを作成するアクション
  def create
    follower = User.find(params[:follower_id])
    following = User.find(params[:following_id])

    follow = Follow.new(follower: follower, following: following)

    if follow.save
      render json: { message: 'フォローしました' }, status: :created
    else
      render json: { errors: follow.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # フォローを解除するアクション
  def destroy
    follower = User.find(params[:follower_id])
    following = User.find(params[:following_id])

    follow = Follow.find_by(follower: follower, following: following)

    if follow&.destroy
      render json: { message: 'フォローを解除しました' }, status: :ok
    else
      render json: { error: 'フォロー解除に失敗しました' }, status: :unprocessable_entity
    end
  end
end
