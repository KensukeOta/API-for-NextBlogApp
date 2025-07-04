class UserSocialProfile < ApplicationRecord
  belongs_to :user

  validates :provider, presence: true, uniqueness: { scope: :user_id }
  validates :url, format: { with: URI::DEFAULT_PARSER.make_regexp }, allow_blank: true, length: { maximum: 255 }
end
