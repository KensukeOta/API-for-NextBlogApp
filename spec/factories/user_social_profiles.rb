FactoryBot.define do
  factory :user_social_profile do
    provider { "twitter" }
    url { "https://twitter.com/example" }
    association :user
  end
end
