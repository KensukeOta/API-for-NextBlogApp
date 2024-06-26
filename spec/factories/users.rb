FactoryBot.define do
  factory :user do
    uid      { "101207280839905116767" }
    name     { "kensuke" }
    email    { "bump.kensuke.miwa@gmail.com" }
    password { "hogehoge" }
    password_confirmation { password }
    image    { "https://lh3.googleusercontent.com/a/ACg8ocKTXZ1p1x6A5yf5c3XFJhY6zt8v7A3eavpOjFxeGFI9WVURhg=s96-c" }
    provider { "credentials" }
  end

  factory :oauth_user, class: "User"  do
    uid      { "101207280839905116767" }
    name     { "oauth_user" }
    email    { "bump.kensuke.miwa@gmail.com" }
    password { SecureRandom.hex(10) }
    password_confirmation { password }
    image    { "https://lh3.googleusercontent.com/a/ACg8ocKTXZ1p1x6A5yf5c3XFJhY6zt8v7A3eavpOjFxeGFI9WVURhg=s96-c" }
    provider { "google" }
  end
end
