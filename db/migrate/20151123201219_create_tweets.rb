class CreateTweets < ActiveRecord::Migration
  def change
    create_table :tweets do |t|
      t.string :twitter_id
      t.string :tweet_text
      t.string :tweet_date
      t.string :tweet_time
      t.integer :retweet_count

      t.timestamps null: false
    end
  end
end
