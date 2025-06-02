class ApplicationController < ActionController::API
  attr_reader :current_user

  private

    def find_current_user_by_header
      user_id = request.headers["X-USER-ID"]
      Rails.logger.debug "X-USER-ID header: #{user_id.inspect}"
      if user_id.present?
        user = User.find_by(id: user_id)
        if user
          @current_user = user
        else
          render_unauthorized
        end
      else
        render_unauthorized
      end
    end

    def render_unauthorized
      render json: { error: "認証が必要です" }, status: :unauthorized
    end
end
