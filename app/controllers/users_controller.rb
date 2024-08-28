class UsersController < ApplicationController
  def index
    if user_params[:email] && user_params[:provider]
      @user = User.includes(:posts).find_by(email: user_params[:email], provider: user_params[:provider])
    end
    if user_params[:name]
      @user = User.includes(:posts, :likes, :tags).find_by(name: user_params[:name])
    end
    
    if @user
      @posts = @user.posts.order(created_at: :desc)
      @likes = @user.likes.order(created_at: :desc)
      @tags = @user.tags

      render json: @user.as_json.merge(posts: @posts, likes: @likes.as_json(include: { post: { include: [:user, :likes, :tags] } }), tags: @tags.as_json), include: { user: {}, likes: {}, tags: {} }, status: :ok
    else
      @users = User.all
      render json: @users, status: :ok
    end
  end
  
  def create
    @user = User.find_or_initialize_by(email: user_params[:email], provider: user_params[:provider])
    
    if @user.persisted?
      render json: { error: "ユーザーは既に存在します" }, status: :unprocessable_entity
      return
    end

    # パスワードが提供されている場合のみ設定します
    if user_params[:password].present?
      @user.password = user_params[:password]
      @user.password_confirmation = user_params[:password_confirmation]
    end

    @user.assign_attributes(user_params.except(:password, :password_confirmation))
    
    if @user.save
      render json: @user, status: :created, location: @user
    else
      render json: { error: @user.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  def update_tags
    @user = User.find(params[:id])

    if params[:tags].present?
      @user.tags.clear
      process_user_tags(@user, params[:tags])
      render json: @user, include: :tags, status: :ok
    else
      render json: { error: "タグが提供されていません" }, status: :unprocessable_entity
    end
  end

  private

    def user_params
      params.permit(:uid, :name, :email, :image, :provider, :password, :password_confirmation)
    end

    def process_user_tags(user, tags)
      tags.each do |tag_name|
        next if tag_name.strip.blank?

        tag = Tag.find_or_create_by(name: tag_name.strip)
        user.tags << tag unless user.tags.include?(tag)
      end
    end
end
