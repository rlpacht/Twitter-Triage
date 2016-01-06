require 'time'
require 'uri'

class Tweet < ActiveRecord::Base

  def mentions_length
    text = tweet_text.split(" ")
    mentions = text.select do |word|
      word.index('@') == 0 && word.length > 1
    end
    return mentions.join(" ").length
  end

  def user_source
    "http://twitter.com/#{user}"
  end

  def source_url
    "http://twitter.com/#{user}/status/#{twitter_id}"
  end

  def formatted_date
    t = tweet_date.localtime
    "#{t.month}/#{t.day}/#{t.year} at #{t.hour}:#{padded_minutes(t.min)}"
  end

  def formatted_age
    seconds = age_in_seconds()
    minutes = seconds / 60
    if minutes == 0
      return "#{seconds}s"
    else
      hours = minutes / 60
      if hours == 0
        return "#{minutes}m"
      else
        days = hours / 24
        if days == 0
          return "#{hours}h"
        else
          weeks = days / 7
          if weeks == 0
            return "#{days}d"
          else
            return "#{weeks}w"
          end
        end
      end
    end
  end

  def reply_message
    return URI.encode("Snap a selfie with http://melange.com and we'll mix custom foundation to perfectly match your skin! Try it for free!")
  end

  def self.pending
    return Tweet.where({
      rejected: false,
      favorited: false,
      done: false
    })
  end

  def self.text_without_urls(tweet_text)
    tweet_text.gsub(/(?:f|ht)tps?:\/[^\s]+/, "")
  end

  def self.add_tweets_to_db(tweets_data)
    tweets_to_verify = Tweet.extract_retweets(tweets_data)
    tweets_added_counter = 0
    tweets_to_verify.each do |tweet_data|
      Tweet.validate_and_create(tweet_data)
    end
    tweets_added_counter
  end

  def self.validate_and_create(tweet_data)
    if Tweet.is_tweet_valid?(tweet_data)
      new_tweet = Tweet.create({
        twitter_id: tweet_data[:id_str],
        tweet_text: tweet_data[:text],
        tweet_date: Time.parse(tweet_data[:created_at]),
        retweet_count: tweet_data[:retweet_count],
        user: tweet_data[:user][:screen_name],
        users_followers: tweet_data[:user][:followers_count],
        favorite_count: tweet_data[:favorite_count],
        non_url_text: Tweet.text_without_urls(tweet_data[:text])
      })
      if new_tweet.email_sent == false
        if tweet_data[:user][:followers_count] >= 15000 || tweet_data[:retweet_count] >= 5 || tweet_data[:favorite_count] >= 15
          UserMailer.important_email(new_tweet).deliver_now
        end
      end
    else
      Blacklist.find_or_create_by({tweet_id: tweet_data[:id_str]})
    end
  end

  private

  def age_in_seconds
    (Time.now - tweet_date).to_i
  end

  def padded_minutes(minutes)
    if minutes < 10
      return "0#{minutes}"
    else
      return minutes
    end
  end

  def self.extract_retweets(tweets_data)
    tweets_data.map do |tweet_data|
      if Tweet.is_retweet?(tweet_data)
        Blacklist.find_or_create_by({tweet_id: tweet_data[:id_str]})
        tweet_data[:retweeted_status]
      else
        tweet_data
      end
    end
  end

  def self.unique_text_and_id?(tweet_data)
    text = Tweet.text_without_urls(tweet_data[:text])
    id = tweet_data[:id_str]
    return !Tweet.exists?(:non_url_text => text) &&
      !Tweet.exists?(:twitter_id => id)
  end

  def self.contains_blacklist?(tweet_text, blacklist)
    blacklist.any? do |bad_phrase|
      tweet_text.downcase.include?(bad_phrase)
    end
  end

  def self.is_retweet?(tweet_data)
    return !tweet_data[:retweeted_status].nil?
  end

  def self.is_tweet_melange?(tweet_data)
    return tweet_data[:user][:screen_name] == "Melange"
  end

  def self.is_user_blacklisted?(tweet_data)
    UserBlacklist.exists?({user: tweet_data[:user][:screen_name]})
  end

  def self.is_tweet_valid?(tweet_data)
    tweet_text = tweet_data[:text]
    return Tweet.unique_text_and_id?(tweet_data) &&
      !Tweet.contains_blacklist?(tweet_text, ["deal", "offer", "ebay", "charitable", "hospital", "donation", "grant"]) &&
      !Tweet.is_tweet_melange?(tweet_data) &&
      !Tweet.is_user_blacklisted?(tweet_data)
  end
end
