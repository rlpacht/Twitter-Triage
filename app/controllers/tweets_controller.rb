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
    @tweets = Tweet.pending.order(tweet_date: :desc).page(params[:page])
    render :index
  end

  def fetch_tweets
    LastFetched.create({last_fetched:Time.now})
    searched_tweets = search_for_tweets
    existing_ids_set = Set.new(Tweet.pluck(:twitter_id) + Blacklist.pluck(:tweet_id))
    new_tweets = searched_tweets.select do |tweet|
      !existing_ids_set.include?(tweet[:id_str])
    end
    Tweet.add_tweets_to_db(new_tweets)
    redirect_to "/"
  end


  # keywords is an array of arrays containing the keywords
  # this method iterates through that array, join the keywords,
  # and then perform the search
  def search_for_tweets
    twitter_client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV["twitter_key"]
      config.consumer_secret     = ENV["twitter_secret"]
      config.access_token        = ENV["twitter_access_token"]
      config.access_token_secret = ENV["twitter_access_token_secret"]
    end
    # there are 15 terms in this query, more terms could be added,
    # but no tweets matching all of the criteria will be found



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
    @tweets = Tweet.where(rejected: true).page(params[:page])
    render :rejected
  end

  def mark_rejected
    mark_property(:rejected, params[:id])
  end

  def done
    @tweets = Tweet.where(done: true).page(params[:page])
    render :done
  end

  def mark_done
    mark_property(:done, params[:id])
  end

  def favorited
    @tweets = Tweet.where(favorited: true).page(params[:page])
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


