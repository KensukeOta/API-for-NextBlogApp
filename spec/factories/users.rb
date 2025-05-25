FactoryBot.define do
  factory :user do
    sequence(:name)       { |n| "testuser#{n}" }
    sequence(:email)      { |n| "user#{n}@example.com" }
    provider              { "credentials" }
    password              { "password123" }
    password_confirmation { "password123" }
    image                 { nil }
  end
end
