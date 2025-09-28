class CreateTags < ActiveRecord::Migration[8.0]
  def change
    create_table :tags do |t|
      t.string :guild_id, null: false
      t.references :user, null: false, foreign_key: true

      t.string :name, null: false
      t.text :content, null: false

      t.timestamps null: false
    end

    add_index :tags, [ :name, :guild_id ], unique: true
  end
end
