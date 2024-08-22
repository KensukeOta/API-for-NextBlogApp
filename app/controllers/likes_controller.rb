class LikesController < ApplicationController
  def create
    @like = Like.new(like_params)
    
    if @like.save
      render json: { message: 'Like created successfully', like: @like }, status: :created
    else
      render json: { errors: @like.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @like = Like.find(params[:id])

    if @like.destroy
      render json: { message: 'Like destroyed successfully' }, status: :ok
    else
      render json: { errors: 'Failed to destroy like' }, status: :unprocessable_entity
    end
  end

  private

  def like_params
    params.require(:like).permit(:user_id, :post_id)
  end
end
