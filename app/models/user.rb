class User < ApplicationRecord
  has_secure_password
  has_many :posts, dependent: :destroy

  has_many :likes, dependent: :destroy
  has_many :liked_posts, through: :likes, source: :post

  has_many :user_social_profiles, dependent: :destroy

  has_many :user_tags, dependent: :destroy
  has_many :tags, through: :user_tags

  has_many :sent_messages, class_name: "Message", foreign_key: "from_user_id", dependent: :destroy
  has_many :received_messages, class_name: "Message", foreign_key: "to_user_id", dependent: :destroy

  # フォローしているユーザー達
  has_many :following_relationships, class_name: "Follow", foreign_key: :follower_id, dependent: :destroy
  has_many :following, through: :following_relationships, source: :followed

  # 自分をフォローしてくれているユーザー達
  has_many :follower_relationships, class_name: "Follow", foreign_key: :followed_id, dependent: :destroy
  has_many :followers, through: :follower_relationships, source: :follower

  validates :name, presence: true, uniqueness: true, length: { minimum: 3, maximum: 32 }
  validates :email, presence: true, uniqueness: { scope: :provider }, length: { maximum: 255 }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :provider, presence: true
  validates :password, length: { minimum: 8, maximum: 64 }, allow_nil: true
  validates :bio, length: { maximum: 200 }
end
