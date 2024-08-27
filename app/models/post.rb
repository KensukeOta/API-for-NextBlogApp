class Post < ApplicationRecord
  belongs_to :user
  has_many :likes, dependent: :destroy
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags

  validates :title,   presence: true, length: { maximum: 50 }
  validates :body,    presence: true, length: { maximum: 10000 }
  validates :user_id, presence: true
end
