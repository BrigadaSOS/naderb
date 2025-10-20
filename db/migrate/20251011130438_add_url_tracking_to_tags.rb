class AddUrlTrackingToTags < ActiveRecord::Migration[8.0]
  def change
    add_column :tags, :original_image_url, :text
    add_column :tags, :discord_cdn_url, :text
  end
end
