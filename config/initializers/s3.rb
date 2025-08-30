require "aws-sdk-s3"

S3_CLIENT = Aws::S3::Client.new(
  endpoint: ENV.fetch("S3_ENDPOINT"),
  force_path_style: true, # MinIO では必須
  region: ENV.fetch("S3_REGION"),
  access_key_id: ENV.fetch("S3_ACCESS_KEY_ID"),
  secret_access_key: ENV.fetch("S3_SECRET_ACCESS_KEY")
)

S3_BUCKET = ENV.fetch("S3_BUCKET")
S3_PUBLIC_HOST = ENV.fetch("S3_PUBLIC_HOST") # 例: http://localhost:9000
