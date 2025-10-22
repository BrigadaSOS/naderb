class CreateTags < ActiveRecord::Migration[8.0]
  def change
    create_table :tags, id: false do |t|
      t.binary :user_id, limit: 16, null: false, index: true

      t.binary :id, limit: 16, null: false, index: { unique: true }, primary_key: true
      t.string :guild_id, null: false

      t.string :name, null: false
      t.text :content
      t.text :original_image_url
      t.text :discord_cdn_url

      t.timestamps null: false
    end

    add_index :tags, [ :name, :guild_id ], unique: true
  end
end
