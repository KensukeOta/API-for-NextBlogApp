class Follow < ApplicationRecord
  belongs_to :follower, class_name: 'User'
  belongs_to :following, class_name: 'User'

  # 同じユーザー間での重複したフォローを防ぐバリデーション
  validates :follower_id, uniqueness: { scope: :following_id }
end
