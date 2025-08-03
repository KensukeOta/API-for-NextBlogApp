class MessagesController < ApplicationController
  before_action :authorize_request

  # GET /v1/messages?with_user_id=2
  # あるユーザーとのやりとり一覧を取得（時系列ソート）
  def index
    if params[:with_user_id].present?
      # 2者間のメッセージ一覧（今まで通り）
      partner = User.find_by(id: params[:with_user_id])
      unless partner
        return render json: { error: "相手ユーザーが存在しません" }, status: :not_found
      end

      messages = Message
        .where("(from_user_id = :me AND to_user_id = :other) OR (from_user_id = :other AND to_user_id = :me)",
              me: current_user.id, other: params[:with_user_id])
        .order(created_at: :asc)

      return render json: {
        partner: partner.as_json(only: [ :id, :name, :image ]),
        messages: messages.as_json(
          only: [ :id, :from_user_id, :to_user_id, :content, :read, :created_at ]
        )
      }
    end

    # ★ここから会話単位のロジック
    # 1. 自分が関わる全メッセージ
    all_messages = Message
      .where("from_user_id = :me OR to_user_id = :me", me: current_user.id)
      .order(created_at: :desc)

    # 2. 会話相手のIDを全て集めてSet化（重複なし）
    partner_ids = all_messages.map { |message|
      message.from_user_id == current_user.id ? message.to_user_id : message.from_user_id
    }.uniq

    users_hash = User.where(id: partner_ids).index_by(&:id)

    # 3. 「相手ごと」に分けて最新メッセージを抽出
    conversations = {}
    all_messages.each do |message|
      # 会話相手のid
      partner_id = message.from_user_id == current_user.id ? message.to_user_id : message.from_user_id

      # まだ未登録ならこのメッセージが一番新しい（orderで降順にしてるため）
      unless conversations.key?(partner_id)
        # 未読件数（自分が受信者で、未読の数）
        unread_count = Message.where(
          from_user_id: partner_id,
          to_user_id: current_user.id,
          read: false
        ).count

        partner_user = users_hash[partner_id]
        conversations[partner_id] = {
          partner: partner_user&.as_json(only: [ :id, :name, :image ]),
          last_message: message.as_json(only: [ :id, :from_user_id, :to_user_id, :content, :read, :created_at ]),
          unread_count: unread_count
        }
      end
    end

    render json: { conversations: conversations.values }
  end

  # POST /v1/messages
  def create
    to_user = User.find_by(id: message_params[:to_user_id])
    return render json: { error: "宛先ユーザーが存在しません" }, status: :not_found unless to_user

    # 自分自身宛は拒否してもよい（仕様次第でallowも可）
    if to_user.id == current_user.id
      return render json: { error: "自分宛にはメッセージを送れません" }, status: :forbidden
    end

    message = Message.new(
      from_user: current_user,
      to_user: to_user,
      content: message_params[:content]
    )

    if message.save
      render json: message.as_json(
        only: [ :id, :from_user_id, :to_user_id, :content, :read, :created_at ]
      ), status: :created
    else
      render json: { errors: message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /v1/messages/:id/read
  # 既読化
  def read
    message = Message.find_by(id: params[:id], to_user: current_user)
    return render json: { error: "メッセージが見つかりません" }, status: :not_found unless message

    message.update(read: true)
    render json: { message: "既読にしました" }
  end

  private

    def message_params
      params.expect(message: [ :to_user_id, :content ])
    end
end
