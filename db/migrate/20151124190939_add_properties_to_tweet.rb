class AddPropertiesToTweet < ActiveRecord::Migration
  def change
    change_table :tweets do |t|
      t.string :tweet_link
      t.string :user
      t.integer :users_followers
      t.boolean :retweeted_status
    end
  end
end
