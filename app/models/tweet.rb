require 'time'
require 'uri'

class Tweet < ActiveRecord::Base

  def user_source
    "http://twitter.com/#{user}"
  end

  def source_url
    "http://twitter.com/#{user}/status/#{twitter_id}"
  end

  def formatted_date
    t = tweet_date
    "#{t.month}/#{t.day}/#{t.year} at #{t.hour}:#{padded_minutes(t.min)}"
  end

  def twitter_id_number
    twitter_id.to_i
  end

  def self.tweets_last_fetched
    t = LastFetched.last.last_fetched
    "#{t.month}/#{t.day}/#{t.year} at #{t.hour}:#{LastFetched.padded_minutes(t.min)}"
  end

  def formatted_age
    seconds = age_in_seconds
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

  def self.add_tweets_to_db(tweets_data)
    tweets_to_verify = Tweet.extract_retweets(tweets_data)
    tweets_to_verify.each do |tweet_data|
      if Tweet.is_tweet_valid?(tweet_data)
        Tweet.create({
          twitter_id: tweet_data[:id_str],
          tweet_text: tweet_data[:text],
          tweet_date: Time.parse(tweet_data[:created_at]),
          retweet_count: tweet_data[:retweet_count],
          user: tweet_data[:user][:screen_name],
          users_followers: tweet_data[:user][:followers_count],
          favorite_count: tweet_data[:favorite_count]
        })
      else
        Blacklist.find_or_create_by({tweet_id: tweet_data[:id_str]})
      end
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

  # def self.convert_url_to_id(tweet_url)
  #   last_slash_index = tweet_url.rindex("/")
  #   tweet_url[(last_slash_index + 1)..-1]
  # end

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
    text = tweet_data[:text]
    id = tweet_data[:id_str]
    return !Tweet.exists?(:tweet_text => text) &&
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

  def self.is_tweet_valid?(tweet_data)
    tweet_text = tweet_data[:text]
    return Tweet.unique_text_and_id?(tweet_data) &&
      !Tweet.contains_blacklist?(tweet_text, ["deal", "offer"]) &&
      !Tweet.is_tweet_melange?(tweet_data)
  end
end
