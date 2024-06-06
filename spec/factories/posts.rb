FactoryBot.define do
  factory :post do
    sequence(:title)  { |n| "Title #{n}" }
    body              { "Hello World" }
    association :user
  end
end
