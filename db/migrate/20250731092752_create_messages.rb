class CreateMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :messages, id: :uuid do |t|
      t.references :from_user, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :to_user, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.text :content, null: false
      t.boolean :read, default: false, null: false

      t.timestamps
    end
  end
end
