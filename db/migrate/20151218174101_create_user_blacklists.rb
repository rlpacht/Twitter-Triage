class CreateUserBlacklists < ActiveRecord::Migration
  def change
    create_table :user_blacklists do |t|
      t.string :user

      t.timestamps null: false
    end
  end
end
