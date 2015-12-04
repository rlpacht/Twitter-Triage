class RemoveTweetsDateColumn < ActiveRecord::Migration
  def change
    remove_column(:tweets, :tweet_date)
    remove_column(:tweets, :tweet_time)
  end
end
