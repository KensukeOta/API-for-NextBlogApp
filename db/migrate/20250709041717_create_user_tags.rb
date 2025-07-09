class CreateUserTags < ActiveRecord::Migration[8.0]
  def change
    create_table :user_tags, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :tag, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :user_tags, [ :user_id, :tag_id ], unique: true
  end
end
