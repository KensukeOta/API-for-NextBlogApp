class FollowsController < ApplicationController
  # フォローを作成するアクション
  def create
    follower = User.find(params[:follower_id])
    following = User.find(params[:following_id])

    follow = Follow.new(follower: follower, following: following)

    if follow.save
      render json: { message: "フォローしました" }, status: :created
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
      render json: { message: "フォローを解除しました" }, status: :ok
    else
      render json: { error: "フォロー解除に失敗しました" }, status: :unprocessable_entity
    end
  end

  # フォローしたユーザーを新しい順に返すアクション
  def recent_followings
    user = User.find_by(name: params[:name])
    followings = user.followings.order("follows.created_at DESC")

    render json: followings.as_json(
      include:{
        posts: {},
        tags: {},
        followings: {},
        followers: {},
        follows_as_follower: {},
        follows_as_following: {},
      }
    ), status: :ok
  end

  # フォローされているユーザーを新しい順で返すアクション
  def recent_followers
    user = User.find_by(name: params[:name])
    followers = user.followers.order("follows.created_at DESC")

    render json: followers.as_json(
      include:{
        posts: {},
        tags: {},
        followings: {},
        followers: {},
        follows_as_follower: {},
        follows_as_following: {},
      }
    ), status: :ok
  end
end
