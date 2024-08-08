require 'rails_helper'

RSpec.describe "PostsApis", type: :request do
  before do
    FactoryBot.create(:post, title: "Sample Post")
    FactoryBot.create(:post, title: "Second Sample Post")
  end
  describe "GET /v1/posts" do
    # 200レスポンスを返すこと
    it "returns a 200 response" do
      get posts_path
      expect(response).to have_http_status(:success)
      # json = JSON.parse(response.body)["allPosts"]
      # puts json["allPosts"][0]["id"]
      # puts json[0]["id"]
    end

    # 記事を全件返すこと
    it "returns all posts" do
      get posts_path
      json = JSON.parse(response.body)["allPosts"]
      expect(json.length).to eq 2
    end

    # 渡されてきたクエリに合致する記事を返すこと
    it "return the post that matches the given query" do
      get "/v1/posts?query=Second Sample Post"
      json = JSON.parse(response.body)
      titles = json["allPosts"].map { |post| post["title"] }
      
      expect(titles).to include "Second Sample Post"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /v1/post/:id" do
    # 200レスポンスを返すこと
    it "returns a 200 response" do
      get post_path(1)
      expect(response).to have_http_status(:success)
    end
    
    # 指定された記事を1件返すこと
    it "return one post" do
      get post_path(1)
      json = JSON.parse(response.body)["post"]
      expect(json["title"]).to eq "Sample Post"
    end
  end

  describe "POST /v1/posts" do
    before do
      @user = FactoryBot.create(:user)
    end
    # 記事を作成できること
    it "creates a post" do
      post_attributes = FactoryBot.attributes_for(:post, user_id: @user.id)
      
      expect {
        post posts_path, params: {
          post: post_attributes
        }
      }.to change(@user.posts, :count).by(1)

      expect(response).to have_http_status(:created)
    end
  end

  describe "PATCH /v1/post/:id" do
    before do
      @post = FactoryBot.create(:post)
    end
    # 記事を更新できること
    it "updates a post" do
      post_attributes = FactoryBot.attributes_for(:post, title: "Update Sample Post")
      patch post_path(@post.id), params: { post: post_attributes }
      expect(@post.reload.title).to eq "Update Sample Post"

      expect(response).to have_http_status(:success)
    end
  end

  describe "DELETE /v1/post/:id" do
    before do
      @user = FactoryBot.create(:user)
      @post = FactoryBot.create(:post, user: @user)
    end

    # 記事を削除できること
    it "deletes a post" do
      expect {
        delete post_path(@post.id)
      }.to change(@user.posts, :count).by(-1)

      expect(response).to have_http_status(:success)
    end
  end
end
