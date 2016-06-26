class RemoveBadTables < ActiveRecord::Migration
  def change
    drop_table :posts
    drop_table :users
  end
end
