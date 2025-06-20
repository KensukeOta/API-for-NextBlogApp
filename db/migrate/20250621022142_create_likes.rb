class CreateLikes < ActiveRecord::Migration[8.0]
  def change
    create_table :likes, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :post, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :likes, [ :user_id, :post_id ], unique: true
  end
end
