class Post < ApplicationRecord
  belongs_to :user

  validates :title,   presence: true, length: { maximum: 50 }
  validates :body,    presence: true, length: { maximum: 10000 }
  validates :user_id, presence: true
end
