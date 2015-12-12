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
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
class TweetsController < ApplicationController

  def index
    @tweets = Tweet.pending.order(tweet_date: :desc).limit(1000)
    render :index
  end

  def fetch_tweets
    searched_tweets = search_for_tweets
    existing_ids_set = Set.new(Tweet.pluck(:twitter_id) + Blacklist.pluck(:tweet_id))

    new_tweets = searched_tweets.select do |tweet|
      !existing_ids_set.include?(tweet[:id_str])
    end
    Tweet.add_tweets_to_db(new_tweets)
    redirect_to "/"
  end

  def search_for_tweets
    twitter_client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV["twitter_key"]
      config.consumer_secret     = ENV["twitter_secret"]
      config.access_token        = ENV["twitter_access_token"]
      config.access_token_secret = ENV["twitter_access_token_secret"]
    end
    # there are 15 terms in this query, more terms could be added,
    # but no tweets matching all of the criteria will be found
    keywords = [
      '"makeup color"',
      '"makeup matching"',
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
    ]
    keywords_joined = keywords.join(" OR ")
    search_query = URI.encode(keywords_joined)
    searched_tweets = twitter_client.search(search_query).attrs[:statuses]

  end

  # def fetch_tweets
  #   # client = Google::APIClient.new
  #   @session = GoogleDrive.saved_session("./stored_token.json", nil, ENV["google_id"], ENV["google_secret"])
  #   # @session = GoogleDrive.saved_session("./stored_token.json", nil, "650842291969-dejntreh6e5q3027jq1tj78j2jj2c05q.apps.googleusercontent.com", "gIn4Ds4jxCczSwbTnwT92v9z")

  #   folder = @session.collection_by_title("fake_data")
  #   spreadsheets = folder.spreadsheets

  #   twitter_client = Twitter::REST::Client.new do |config|
  #     config.consumer_key        = ENV["twitter_key"]
  #     config.consumer_secret     = ENV["twitter_secret"]
  #     config.access_token        = ENV["twitter_access_token"]
  #     config.access_token_secret = ENV["twitter_access_token_secret"]
  #   end

  #   twitter_data = get_twitter_data_from_spreadsheets(twitter_client, spreadsheets)

  #   Tweet.add_tweets_to_db(twitter_data)
  #   redirect_to "/"
  # end

  def rejected
    @tweets = Tweet.where(rejected: true)
    render :rejected
  end

  def mark_rejected
    mark_property(:rejected, params[:id])
  end

  def done
    @tweets = Tweet.where(done: true)
    render :done
  end

  def mark_done
    mark_property(:done, params[:id])
  end

  def favorited
    @tweets = Tweet.where(favorited: true)
    render :favorited
  end

  def mark_favorited
    mark_property(:favorited, params[:id])
  end

  private

  # def get_twitter_data_from_spreadsheets(twitter_client, spreadsheets)
  #   ids = get_column_data(spreadsheets, 4).uniq
  #   start_index = 0
  #   end_index = 100
  #   twitter_data = []
  #   # twitter will not let you make more than 15 requests every fifteen minutes
  #   # the counter is to prevent it from breaking
  #   counter = 0
  #   new_ids = ids - Tweet.pluck(:twitter_id) - Blacklist.pluck(:tweet_id)
  #   while start_index < new_ids.length && counter < 5
  #     bucket_of_ids = new_ids[start_index...end_index]
  #     twitter_data.concat(fetch_tweets_bucket(twitter_client, bucket_of_ids))
  #     start_index += 100
  #     end_index += 100
  #     counter += 1
  #   end

  #   return twitter_data
  # end

  def mark_property(column, id)
    tweet = Tweet.find(id)
    tweet.update({column => true})
    tweet.save
    redirect_to "/"
  end

  # def get_column_data(spreadsheets, column_number)
  #   column_data = []
  #   spreadsheets.each do |spreadsheet|
  #     p "SPREADSHEET"
  #     worksheet = spreadsheet.worksheets[0]
  #     column_data.concat(get_ids_in_column(worksheet, column_number))
  #   end
  #   return column_data
  # end

  # def get_ids_in_column(worksheet, column_number)
  #   (1..worksheet.num_rows).to_a.map do |row_number|
  #     tweet_url = worksheet[row_number, column_number]
  #     Tweet.convert_url_to_id(tweet_url)
  #   end
  # end

  # Only for one bucket of up to 100 ids. ids must be strings
  # def fetch_tweets_bucket(client, ids)
  #   ids_string = ids.join(',')
  #   request_options = {id: ids_string}
  #   twitter_request = Twitter::REST::Request.new(client, :get, "1.1/statuses/lookup.json",  request_options)
  #   twitter_request.perform
  # end

end


