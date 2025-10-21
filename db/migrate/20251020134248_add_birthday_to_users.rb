class AddBirthdayToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :birthday_month, :integer, comment: "Month of birth (1-12), nil if not set"
    add_column :users, :birthday_day, :integer, comment: "Day of birth (1-31), nil if not set"
  end
end
