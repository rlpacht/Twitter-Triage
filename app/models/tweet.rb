require 'time'
require 'uri'

class Tweet < ActiveRecord::Base

  SEARCH_KEYWORDS = [
    "foundation struggle",
    "foundation mix",
    "foundation blend",
    "foundation shade",
    "foundation tone",
    "foundation undertone",
    "foundation skintone",
    "foundation tan",
    "foundation tanned",
    "foundation pale",
    "foundation palest",
    "foundation light",
    "foundation lightest",
    "foundation color",
    "foundation colour",
    "foundation match",
    "foundation matching",
    "foundation mixing",
    "foundation brown",
    "foundation dark",
    "foundation darkest",
    "foundation yellow",
    "foundation black",
    "foundation grey",
    "foundation gray",
    "foundation ashy",
    "foundation orange",
    "makeup matching",
    "makeup mix",
    "makeup mixing",
    "makeup shade",
    "makeup tone",
    "makeup undertone",
    "makeup skintone",
    "makeup woc",
    "makeup pale",
    "makeup brown",
    "makeup dark",
    "makeup yellow",
    "makeup black",
    "makeup grey",
    "makeup gray",
    "makeup ashy",
    "makeup orange",
    "concealer color",
    "concealer matching",
    "concealer match",
    "concealer mix",
    "concealer mixing",
    "concealer shade",
    "concealer tone",
    "concealer undertone",
    "concealer skintone",
    "concealer tan",
    "concealer tanned",
    "concealer woc",
    "concealer pale",
    "concealer light",
    "concealer brown",
    "concealer dark",
    "concealer yellow",
    "concealer black",
    "concealer grey",
    "concealer gray",
    "concealer ashy",
    "concealer orange",
    "concealer struggle"
  ]

  GRAY_LIST = [
    "dark circles",
    "mood",
    "product review",
    "lipstick",
    "lips",
    "lip",
    "lipgloss",
    "blush",
    "bitch",
    "bitches",
    "ladies",
    "girls",
    "$",
    ":",
    "|",
    "she",
    "he",
    "girl",
    "her",
    "him",
    "his",
    "tip",
    "tips",
    "eyeliner",
    "eyeshadow",
    "eyes",
    "eye",
    "under eye circles",
    "mascara",
    "winged line",
    "lashes",
    "brow",
    "brows",
    "eyebrow",
    "eyebrows",
    "hair",
    "curls",
    "wash",
    "washes",
    "washing",
    "take off",
    "nail",
    "nails",
    "sleep",
    "bed",
    "brush",
    "brushes",
    "pencil",
    "pencils",
    "outfit",
    "clothes",
    "clothing",
    "shirt",
    "smokey",
    "smoky",
    "blog post",
    "table light",
    "ring light",
    "glitter",
    "glitters",
    "shoe",
    "shoes",
    "heels",
    "pimple",
    "pimples",
    "spot",
    "spots",
    "purple",
    "Mary Kay",
    "goth",
    "NEW",
    "@YouTube",
    "CLinton",
    "@WhiteHouse",
    "finally",
    "obsessed",
    "love"
  ]
  # Send an email with this tweet's data if this tweet
  # hasn't already been emailed, and its metrics are
  # sufficiently high
  def email_if_needed
    if !email_sent
      if users_followers >= 15000 || retweet_count >= 5 || favorite_count >= 15
        UserMailer.important_email(self).deliver_now
      end
    end
  end

  # TODO: Use the data from the API for this instead
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

  # def reply_message
  #   return URI.encode("Snap a selfie with http://melange.com and we'll mix custom foundation to perfectly match your skin! Try it for free!")
  # end
  def score
    tweet_score = (Math::E**(age_in_seconds()/100000)) * (retweet_count) * (users_followers) * (favorite_count ** (1/3))
    # tweet_score = (users_followers + favorite_count + retweet_count)/(age_in_seconds + 1.0)
    num_gray_list_words = 0
    Tweet::GRAY_LIST.each do |gray_word|
      if tweet_text.include?(gray_word)
        num_gray_list_words += 1
      end
    end

    tweet_score *= (0.02**num_gray_list_words)
    return tweet_score
  end

  def self.top_ranked
    all_pending = Tweet.pending
    limit = 100
    newest_tweets = all_pending.order("#{:tweet_date} DESC NULLS LAST").limit(limit)
    most_followers = all_pending.order("#{:users_followers} DESC NULLS LAST").limit(limit)
    most_favorites = all_pending.order("#{:favorite_count} DESC NULLS LAST").limit(limit)
    most_retweets = all_pending.order("#{:retweet_count} DESC NULLS LAST").limit(limit)

    top_tweets = newest_tweets
      .concat(most_followers)
      .concat(most_favorites)
      .concat(most_retweets)
      .uniq
    return top_tweets.sort_by { |tweet| -tweet.score }
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
      new_tweet.email_if_needed
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
      !Tweet.contains_blacklist?(tweet_text, ["deal", "offer", "ebay", "charitable", "hospital", "donation", "grant", "educational", "make a wish"]) &&
      !Tweet.is_tweet_melange?(tweet_data) &&
      !Tweet.is_user_blacklisted?(tweet_data)
  end
end
