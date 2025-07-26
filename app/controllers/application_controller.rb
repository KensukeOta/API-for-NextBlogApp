class ApplicationController < ActionController::API
  attr_reader :current_user

  private

    def authorize_request
      header = request.headers["Authorization"]
      header = header.split(" ").last if header.present?
      decoded = JsonWebToken.decode(header)
      if decoded && (user = User.find_by(id: decoded[:user_id]))
        @current_user = user
      else
        render json: { error: "認証が必要です" }, status: :unauthorized
      end
    end
end
