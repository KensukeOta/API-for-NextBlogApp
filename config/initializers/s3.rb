# config/initializers/s3.rb
require "aws-sdk-s3"

if Rails.env.test?
  # CI/ローカルtestではS3に触れない。スタブクライアントで安全に初期化。
  S3_CLIENT = Aws::S3::Client.new(stub_responses: true)
  S3_BUCKET = ENV["S3_BUCKET"] || "user-avatars-test"
  # public URLはテストで実使用されないのでダミーでOK
  S3_PUBLIC_HOST = ENV["S3_PUBLIC_HOST"] || "http://example.com"
else
  # dev/prod は従来通り。ここはENVが必要
  S3_CLIENT = Aws::S3::Client.new(
    endpoint: ENV.fetch("S3_ENDPOINT"),
    force_path_style: true,
    region: ENV.fetch("S3_REGION"),
    access_key_id: ENV.fetch("S3_ACCESS_KEY_ID"),
    secret_access_key: ENV.fetch("S3_SECRET_ACCESS_KEY")
  )

  S3_BUCKET = ENV.fetch("S3_BUCKET")
  S3_PUBLIC_HOST = ENV.fetch("S3_PUBLIC_HOST")
end
