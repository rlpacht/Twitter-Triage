class NewTweetColumns < ActiveRecord::Migration
  def change
    add_column :tweets, :rejected, :boolean, :default => false
    add_column :tweets, :done, :boolean, :default => false
    add_column :tweets, :favorited, :boolean, :default => false
  end
end
