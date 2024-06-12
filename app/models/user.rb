class User < ApplicationRecord
  has_many :posts, dependent: :destroy

  has_secure_password

  # 名前のバリデーション
  validates :name, presence: true, length: { minimum: 2, maximum: 50 }
   # メールアドレスのバリデーション
  validates :email, presence: true, length: { maximum: 254 }, format: { with: URI::MailTo::EMAIL_REGEXP }

  # パスワードのバリデーションをカスタマイズし、OAuth認証時にはパスワードを必須にしない
  validates :password, presence: true, confirmation: true, if: :password_required?
  validates :password_confirmation, presence: true, if: :password_present?

  # パスワードが必要かどうかを判定するメソッド
  # providerが空の場合にパスワードが必須と判断する
  def password_required?
    provider.blank?
  end

  # パスワードが入力されているかどうかを判定するメソッド
  # パスワードが入力されている場合に確認も必須とする
  def password_present?
    password.present?
  end
end
