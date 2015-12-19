require "rubygems"
require "google/api_client"
require "google_drive"
require 'openssl'
require 'twitter'
require 'twitter/rest/request'
require 'twitter/search_results'
require 'net/http'
require 'twitter/headers'
require "json"
require 'uri'
require 'set'
# OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
class TweetsController < ApplicationController

  @@keywords = [
      [
        '"makeup color"',
        '"makeup match"',
        '"foundation struggle"',
        '"concealer color"',
        '"concealer matching"',
        '"foundation mix"',
        '"foundation blend"',
        '"foundation shade"',
        '"foundation tone"',
        '"foundation undertone"',
        '"foundation skintone"',
        '"foundation tan"',
        '"foundation tanned"',
        '"foundation pale"',
        '"foundation light"'
      ],
      [
        '"foundation color"',
        '"foundation colour"',
        '"foundation match"',
        '"foundation matching"',
        '"foundation mixing"',
        '"foundation brown"',
        '"foundation dark"',
        '"foundation yellow"',
        '"foundation black"',
        '"foundation grey"',
        '"foundation gray"',
        '"foundation ashy"',
        '"foundation orange"',
        '"foundation red"',
        '"foundation pink"'
      ],
      [
        '"makeup colour"',
        '"makeup matching"',
        '"makeup mix"',
        '"makeup mixing"',
        '"makeup blend"',
        '"makeup shade"',
        '"makeup tone"',
        '"makeup undertone"',
        '"makeup skintone"',
        '"makeup tan"',
        '"makeup tanned"',
        '"makeup woc"',
        '"makeup pale"',
        '"makeup light"',
        '"makeup brown"'
      ],
      [
        '"makeup dark"',
        '"makeup yellow"',
        '"makeup black"',
        '"makeup grey"',
        '"makeup gray"',
        '"makeup ashy"',
        '"makeup orange"',
        '"makeup red"',
        '"makeup pink"',
        '"makeup struggle"',
        '"concealer colour"',
        '"concealer match"',
        '"concealer mix"',
        '"concealer mixing"',
        '"concealer blend"'
      ],
      [
        '"concealer shade"',
        '"concealer tone"',
        '"concealer undertone"',
        '"concealer skintone"',
        '"concealer tan"',
        '"concealer tanned"',
        '"concealer woc"',
        '"concealer pale"',
        '"concealer light"',
        '"concealer brown"',
        '"concealer dark"',
        '"concealer yellow"',
        '"concealer black"',
        '"concealer grey"',
        '"concealer gray"'
      ],
      [
        '"concealer ashy"',
        '"concealer orange"',
        '"concealer red"',
        '"concealer pink"',
        '"concealer struggle"'
      ]
    ]

  def index
    @page = params[:page]
    if params[:order].nil?
      @order = :tweet_date
      @tweets = Tweet.pending.order("#{@order} DESC NULLS LAST").page(@page)
    else
      @order = params[:order]
      @tweets = Tweet.pending.order("#{@order} DESC NULLS LAST").page(@page)
    end
    # update_tweets(@tweets)
    render :index
  end

  def fetch_tweets
    LastFetched.create({last_fetched: Time.now})
    searched_tweets = search_for_tweets
    existing_ids_set = Set.new(Tweet.pluck(:twitter_id) + Blacklist.pluck(:tweet_id))
    new_tweets = searched_tweets.select do |tweet|
      !existing_ids_set.include?(tweet[:id_str])
    end
    Tweet.add_tweets_to_db(new_tweets)
    redirect_to "/"
  end

  def get_twitter_client
    twitter_client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV["twitter_key"]
      config.consumer_secret     = ENV["twitter_secret"]
      config.access_token        = ENV["twitter_access_token"]
      config.access_token_secret = ENV["twitter_access_token_secret"]
    end
  end

  def search_for_tweets
    # keywords is an array of arrays containing the keywords
    # this method iterates through that array, join the keywords,
    # and then perform the search
    # there are 15 terms in this query, more terms could be added,
    # but no tweets matching all of the criteria will be found

    twitter_client = get_twitter_client

    searched_tweets = []
    most_recent_tweet = Tweet.maximum('twitter_id')
    @@keywords.each do |keyword_group|
      keywords_joined = keyword_group.join(" OR ")
      search_query = URI.encode(keywords_joined)
      new_searched_tweets = twitter_client.search(search_query, {
        :since_id => most_recent_tweet
      }).attrs[:statuses]
      searched_tweets.concat(new_searched_tweets)
    end
    return searched_tweets
  end

  def update_tweets(tweets)
    client = get_twitter_client

    tweet_ids = tweets.map do |tweet|
      tweet.twitter_id
    end
    tweet_ids = tweet_ids.join(",")
    request_options = {id: tweet_ids}
    twitter_request = Twitter::REST::Request.new(client, :get, "1.1/statuses/lookup.json",  request_options)
    updated_tweet_data = twitter_request.perform
    updated_tweet_data.each do |tweet_info|
      tweet_to_update = tweets.find do |tweet|
        tweet.twitter_id == tweet_info[:id_str]
      end
      tweet_to_update.update({
        retweet_count: tweet_info[:retweet_count],
        users_followers: tweet_info[:user][:followers_count],
        favorite_count: tweet_info[:favorite_count]
      })
    end
  end

  def blacklist_user
    page = params[:page]
    order = params[:order] || :tweet_date
    UserBlacklist.create({user: params[:user]})
    blacklist_tweets = Tweet.where({user: params[:user]})
    blacklist_tweets.each do |tweet|
      tweet.update({:rejected => true})
      tweet.save
    end
    redirect_to action: 'index', page: page, order: order
  end

  def rejected
    @tweets = Tweet.where(rejected: true).page(params[:page])
    render :rejected
  end

  def mark_rejected
    order = params[:order] || :tweet_date
    mark_property(:rejected, params[:id], params[:page], order)
  end

  def done
    @tweets = Tweet.where(done: true).page(params[:page])
    render :done
  end

  def mark_done
    order = params[:order] || :tweet_date
    mark_property(:done, params[:id], params[:page], order)
  end

  def favorited
    @tweets = Tweet.where(favorited: true).page(params[:page])
    render :favorited
  end

  def mark_favorited
    order = params[:order] || :tweet_date
    mark_property(:favorited, params[:id], params[:page], order)
  end

  private

  def mark_property(column, id, page, order)
    tweet = Tweet.find(id)
    [:rejected, :done, :favorited].each do |property|
      tweet.update({property => false})
    end
    tweet.update({column => true})
    tweet.save
    redirect_to action: 'index', page: page, order: order
  end
end


