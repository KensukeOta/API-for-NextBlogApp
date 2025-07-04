class UserSocialProfilesController < ApplicationController
  before_action :find_current_user_by_header

  # SNSアカウント新規追加
  def create
    profile = current_user.user_social_profiles.build(user_social_profile_params)

    if profile.save
      render json: {
        user_social_profile: profile.as_json(only: [ :id, :provider, :url ]),
        message: "SNS情報を登録しました"
      }, status: :created
    else
      render json: { errors: profile.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # SNSアカウント編集
  def update
    profile = UserSocialProfile.find_by(id: params[:id])
    unless profile
      return render json: { error: "SNS情報が見つかりません" }, status: :not_found
    end

    unless profile.user_id == current_user.id
      render json: { error: "権限がありません" }, status: :forbidden
      return
    end

    if profile.update(user_social_profile_params)
      render json: {
        user_social_profile: profile.as_json(only: [ :id, :provider, :url ]),
        message: "SNS情報を更新しました"
      }, status: :ok
    else
      render json: { errors: profile.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # SNSアカウント削除
  def destroy
    profile = UserSocialProfile.find_by(id: params[:id])
    unless profile
      return render json: { error: "SNS情報が見つかりません" }, status: :not_found
    end

    unless profile.user_id == current_user.id
      render json: { error: "権限がありません" }, status: :forbidden
      return
    end

    if profile.destroy
      render json: { message: "SNS情報を削除しました" }, status: :ok
    else
      render json: { error: "SNS情報の削除に失敗しました" }, status: :unprocessable_entity
    end
  end

  private

    def user_social_profile_params
      params.expect(user_social_profile: [ :provider, :url ])
    end
end
