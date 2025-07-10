class CreateTags < ActiveRecord::Migration[8.0]
  def change
    create_table :tags, id: :uuid do |t|
      t.string :name, limit: 10

      t.timestamps
    end

    add_index :tags, :name, unique: true
  end
end
