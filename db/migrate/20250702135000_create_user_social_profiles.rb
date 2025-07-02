class CreateUserSocialProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :user_social_profiles, id: :uuid do |t|
      t.string :provider, null: false
      t.string :url, limit: 255
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :user_social_profiles, [ :user_id, :provider ], unique: true
  end
end
