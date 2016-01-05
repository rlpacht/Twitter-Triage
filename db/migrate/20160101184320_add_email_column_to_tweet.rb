class AddEmailColumnToTweet < ActiveRecord::Migration
  def change
    add_column :tweets, :email_sent, :boolean, :default => false
  end
end
