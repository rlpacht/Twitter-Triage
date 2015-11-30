class Tweet < ActiveRecord::Base
  def source_url
    "http://twitter.com/#{user}/status/#{twitter_id}"
  end

  def text
    tweet_text
  end
end
