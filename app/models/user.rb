class User < ApplicationRecord
  has_many :posts, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :user_tags, dependent: :destroy
  has_many :tags, through: :user_tags
  # フォローしているユーザーとの関連付け
  has_many :follows_as_follower, class_name: 'Follow', foreign_key: 'follower_id', dependent: :destroy
  has_many :followings, through: :follows_as_follower, source: :following

  # フォロワーとの関連付け
  has_many :follows_as_following, class_name: 'Follow', foreign_key: 'following_id', dependent: :destroy
  has_many :followers, through: :follows_as_following, source: :follower

  has_secure_password

  # 名前のバリデーション
  validates :name, presence: true, length: { minimum: 2, maximum: 50 }
   # メールアドレスのバリデーション
  validates :email, presence: true, length: { maximum: 254 }, format: { with: URI::MailTo::EMAIL_REGEXP }

  # パスワードのバリデーションをカスタマイズし、OAuth認証時にはパスワードを必須にしない
  validates :password, presence: true, length: { minimum: 8, maximum: 32 }, confirmation: true
  validates :password_confirmation, presence: true, if: :password_present?

  # パスワードが入力されているかどうかを判定するメソッド
  # パスワードが入力されている場合に確認も必須とする
  def password_present?
    password.present?
  end
end
