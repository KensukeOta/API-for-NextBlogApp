class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name, null: false, limit: 32
      t.string :email, null: false, limit: 255
      t.string :password_digest, null: false
      t.string :image
      t.string :provider, null: false

      t.timestamps
    end

    add_index :users, :name, unique: true
    add_index :users, [ :email, :provider ], unique: true
  end
end
