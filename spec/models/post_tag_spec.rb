require 'rails_helper'

RSpec.describe PostTag, type: :model do
  describe "Validation" do
    # 有効なファクトリなら有効
    it "is valid with a valid factory" do
      expect(build(:post_tag)).to be_valid
    end

    # post_idとtag_idの組み合わせがユニークでないと無効
    it "is invalid if the combination of post_id and tag_id is not unique" do
      post = create(:post)
      tag = create(:tag)
      create(:post_tag, post: post, tag: tag)
      dup_post_tag = build(:post_tag, post: post, tag: tag)
      expect(dup_post_tag).to be_invalid
      expect(dup_post_tag.errors[:post_id]).to include("has already been taken")
    end

    # postなしは無効
    it "is invalid without a post" do
      expect(build(:post_tag, post: nil)).not_to be_valid
    end

    # tagなしは無効
    it "is invalid without a tag" do
      expect(build(:post_tag, tag: nil)).not_to be_valid
    end

    describe "Association" do
      # postとtagのアソシエーション
      it "belongs to post and tag" do
        post_tag = create(:post_tag)
        expect(post_tag.post).to be_a(Post)
        expect(post_tag.tag).to be_a(Tag)
      end
    end
  end
end
