class AllowNullContentInTags < ActiveRecord::Migration[8.0]
  def change
    change_column_null :tags, :content, true
  end
end
