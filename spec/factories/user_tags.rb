FactoryBot.define do
  factory :user_tag do
    association :user
    association :tag
  end
end
