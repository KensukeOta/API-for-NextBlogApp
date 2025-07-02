class User < ApplicationRecord
  has_secure_password
  has_many :posts, dependent: :destroy

  has_many :likes, dependent: :destroy
  has_many :liked_posts, through: :likes, source: :post

  has_many :user_social_profiles, dependent: :destroy

  validates :name, presence: true, uniqueness: true, length: { minimum: 3, maximum: 32 }
  validates :email, presence: true, uniqueness: { scope: :provider }, length: { maximum: 255 }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :provider, presence: true
  validates :password, length: { minimum: 8, maximum: 64 }, allow_nil: true
  validates :bio, length: { maximum: 200 }
end
