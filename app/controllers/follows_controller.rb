class FollowsController < ApplicationController
  before_action :authorize_request

  # POST /v1/follows
  def create
    user_to_follow = User.find_by(id: follow_params[:followed_id])
    return render json: { error: "ユーザーが見つかりません" }, status: :not_found unless user_to_follow

    follow = Follow.new(follower: current_user, followed: user_to_follow)
    if follow.save
      render json: { message: "フォローしました" }, status: :created
    else
      render json: { errors: follow.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /v1/follows/:id
  def destroy
    follow = Follow.find_by(id: params[:id], follower: current_user)
    return render json: { error: "フォロー関係が見つかりません" }, status: :not_found unless follow

    follow.destroy
    render json: { message: "フォローを解除しました" }
  end

  # GET /v1/users/:id/followers
  def followers
    user = User.find(params[:id])
    followers = user.followers.select(:id, :name, :image)
    render json: { followers: followers }
  end

  # GET /v1/users/:id/following
  def following
    user = User.find(params[:id])
    following = user.following.select(:id, :name, :image)
    render json: { following: following }
  end

  private

    def follow_params
      params.expect(follow: [ :followed_id ])
    end
end
