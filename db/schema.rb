# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_08_06_055216) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "follows", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "follower_id", null: false
    t.uuid "followed_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["followed_id"], name: "index_follows_on_followed_id"
    t.index ["follower_id", "followed_id"], name: "index_follows_on_follower_id_and_followed_id", unique: true
    t.index ["follower_id"], name: "index_follows_on_follower_id"
  end

  create_table "likes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "post_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_likes_on_post_id"
    t.index ["user_id", "post_id"], name: "index_likes_on_user_id_and_post_id", unique: true
    t.index ["user_id"], name: "index_likes_on_user_id"
  end

  create_table "messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "from_user_id", null: false
    t.uuid "to_user_id", null: false
    t.text "content", null: false
    t.boolean "read", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["from_user_id"], name: "index_messages_on_from_user_id"
    t.index ["to_user_id"], name: "index_messages_on_to_user_id"
  end

  create_table "post_tags", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "post_id", null: false
    t.uuid "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id", "tag_id"], name: "index_post_tags_on_post_id_and_tag_id", unique: true
    t.index ["post_id"], name: "index_post_tags_on_post_id"
    t.index ["tag_id"], name: "index_post_tags_on_tag_id"
  end

  create_table "posts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title", limit: 50, null: false
    t.text "content", null: false
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "tags", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", limit: 10
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "user_social_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "provider", null: false
    t.string "url", limit: 255
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "provider"], name: "index_user_social_profiles_on_user_id_and_provider", unique: true
    t.index ["user_id"], name: "index_user_social_profiles_on_user_id"
  end

  create_table "user_tags", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id"], name: "index_user_tags_on_tag_id"
    t.index ["user_id", "tag_id"], name: "index_user_tags_on_user_id_and_tag_id", unique: true
    t.index ["user_id"], name: "index_user_tags_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", limit: 32, null: false
    t.string "email", limit: 255, null: false
    t.string "password_digest", null: false
    t.string "image"
    t.string "provider", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "bio", limit: 200
    t.index ["email", "provider"], name: "index_users_on_email_and_provider", unique: true
    t.index ["name"], name: "index_users_on_name", unique: true
  end

  add_foreign_key "follows", "users", column: "followed_id"
  add_foreign_key "follows", "users", column: "follower_id"
  add_foreign_key "likes", "posts"
  add_foreign_key "likes", "users"
  add_foreign_key "messages", "users", column: "from_user_id"
  add_foreign_key "messages", "users", column: "to_user_id"
  add_foreign_key "post_tags", "posts"
  add_foreign_key "post_tags", "tags"
  add_foreign_key "posts", "users"
  add_foreign_key "user_social_profiles", "users"
  add_foreign_key "user_tags", "tags"
  add_foreign_key "user_tags", "users"
end
