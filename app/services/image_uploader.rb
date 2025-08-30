class ImageUploader
  # file: ActionDispatch::Http::UploadedFile
  # returns: public URL string
  def self.upload_user_avatar!(user_id:, file:)
    raise ArgumentError, "file is required" unless file

    ext = File.extname(file.original_filename).downcase.presence || ".jpg"
    key = "users/#{user_id}/#{SecureRandom.uuid}#{ext}"

    # アップロード
    S3_CLIENT.put_object(
      bucket: S3_BUCKET,
      key: key,
      body: file.tempfile,
      content_type: file.content_type
    )

    # 開発ではパブリックバケット前提の直リンク
    # MinIO の path-style: http://localhost:9000/<bucket>/<key>
    "#{S3_PUBLIC_HOST}/#{S3_BUCKET}/#{key}"
  end
end
