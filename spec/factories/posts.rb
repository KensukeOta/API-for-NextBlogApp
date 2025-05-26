FactoryBot.define do
  factory :post do
    # タイトルはランダムで50文字以内
    sequence(:title) { |n| "Test Post Title #{n}" }
    # 本文は最低10文字以上、10000文字以内でサンプルを作成
    content { "a" * 50 }
    association :user
  end
end
