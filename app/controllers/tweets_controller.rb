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
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

class TweetsController < ApplicationController
  def index
    client = Google::APIClient.new
    # auth = client.authorization
    # auth.client_id = "683200892791-8m30lam17uijblqsrjeovj7o03a95i26"
    # auth.client_secret = "ysAf0-OnpFop4RdQ3eo0Zwgk"
    # auth.scope =
    #     "https://www.googleapis.com/auth/drive " +
    #     "https://spreadsheets.google.com/feeds/"
    # auth.redirect_uri = "urn:ietf:wg:oauth:2.0:oob"
    # print("1. Open this page:\n%s\n\n" % auth.authorization_uri)
    # print("2. Enter the authorization code shown in the page: ")
    # auth.code = $stdin.gets.chomp
    # auth.fetch_access_token!

    # access_token = auth.access_token

    # # Creates a session.
    # @session = GoogleDrive.login_with_oauth(access_token)

    # auth.redirect_uri = "http://example.com/redirect"
    # auth.refresh_token = refresh_token
    # auth.fetch_access_token!
    @session = GoogleDrive.saved_session("./stored_token.json", nil, "683200892791-8m30lam17uijblqsrjeovj7o03a95i26", "ysAf0-OnpFop4RdQ3eo0Zwgk")
    # @session = GoogleDrive.login_with_oauth(auth.access_token)

    folder = @session.collection_by_title("fake_data")
    spreadsheets = folder.spreadsheets

    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = "BMrfGU77tdpO8ShsO6alnnTbs"
      config.consumer_secret     = "kt7ZEe45lQxMBGJMVlONcrUHthuQtUHUOlOYHwPLhpK8gr9vUW"
      config.access_token        = "711951421-qcGd19poM1IVUO2ZBHwQxakgmlvTXCphouoYjrOP"
      config.access_token_secret = "4bojDnF33AZPUkg6yMlcwGpZObl8IzszjdTToGP032bhe"
    end

    # Tweets from Twitter refered to as tweet_data
    # Tweets from DB refered to as tweet_record

    ids = get_column_data(spreadsheets, 5).uniq
    start_index = 0
    end_index = 100
    twitter_data = []
    new_ids = ids - Tweet.pluck(:twitter_id)
    while start_index < new_ids.length
      bucket_of_ids = new_ids[start_index...end_index]
      twitter_data.concat(fetch_tweets_bucket(client, bucket_of_ids))
      start_index += 100
      end_index += 100
    end
    add_tweets_to_db(twitter_data)
    # render json: twitter_data
    # render json: Tweet.all.order(:users_followers)
    @tweets = Tweet.all
    render :index
  end

  def

  private

  def get_column_data(spreadsheets, column_number)
    column_data = []
    spreadsheets.each do |spreadsheet|
      worksheet = spreadsheet.worksheets[0]
      column_data.concat(get_ids_in_column(worksheet, column_number))
    end
    return column_data
  end

  def get_ids_in_column(worksheet, column_number)
    (2..worksheet.num_rows).to_a.map do |row_number|
      tweet_url = worksheet[row_number, column_number]
      convert_url_to_id(tweet_url)
    end
  end

  def convert_url_to_id(tweet_url)
    last_slash_index = tweet_url.rindex("/")
    tweet_url[(last_slash_index + 1)..-1]
  end

  # Only for one bucket of up to 100 ids. ids must be strings
  def fetch_tweets_bucket(client, ids)
    ids_string = ids.join(',')
    request_options = {id: ids_string}
    twitter_request = Twitter::REST::Request.new(client, :get, "1.1/statuses/lookup.json",  request_options)
    twitter_request.perform
  end

  def add_tweets_to_db(tweets_data)
    tweets_to_verify = tweets_data.map do |tweet_data|
      if is_retweet?(tweet_data)
        tweet_data[:retweeted_status]
      else
        tweet_data
      end
    end

    tweets_to_verify.each do |tweet_data|
      if is_tweet_valid?(tweet_data)
        Tweet.create({
          twitter_id: tweet_data[:id_str],
          tweet_text: tweet_data[:text],
          tweet_date: tweet_data[:created_at],
          retweet_count: tweet_data[:retweet_count],
          user: tweet_data[:user][:screen_name],
          users_followers: tweet_data[:user][:followers_count]
        })
      end
    end
  end

  def unique_text_and_id?(tweet_data)
    text = tweet_data[:text]
    id = tweet_data[:id_str]
    return !Tweet.exists?(:tweet_text => text) &&
      !Tweet.exists?(:twitter_id => id)
  end

  def contains_blacklist?(tweet_text, blacklist)
    blacklist.any? do |bad_phrase|
      tweet_text.downcase.include?(bad_phrase)
    end
  end

  def is_retweet?(tweet_data)
    return !tweet_data[:retweeted_status].nil?
  end

  def is_tweet_valid?(tweet_data)
    tweet_text = tweet_data[:text]
    return unique_text_and_id?(tweet_data) && !contains_blacklist?(tweet_text, ["deals"])
  end

end


