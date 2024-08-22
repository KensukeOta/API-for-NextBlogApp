class Like < ApplicationRecord
  belongs_to :post
  belongs_to :user

  # user_idとpost_idの組み合わせが一意（ユニーク）であることを検証するバリデーション
  validates :user_id, uniqueness: { scope: :post_id }
end
