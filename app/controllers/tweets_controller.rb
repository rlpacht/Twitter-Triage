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
    # client = Google::APIClient.new
    @session = GoogleDrive.saved_session("./stored_token.json", nil, "683200892791-8m30lam17uijblqsrjeovj7o03a95i26", "ysAf0-OnpFop4RdQ3eo0Zwgk")

    folder = @session.collection_by_title("fake_data")
    spreadsheets = folder.spreadsheets

    twitter_client = Twitter::REST::Client.new do |config|
      config.consumer_key        = "BMrfGU77tdpO8ShsO6alnnTbs"
      config.consumer_secret     = "kt7ZEe45lQxMBGJMVlONcrUHthuQtUHUOlOYHwPLhpK8gr9vUW"
      config.access_token        = "711951421-qcGd19poM1IVUO2ZBHwQxakgmlvTXCphouoYjrOP"
      config.access_token_secret = "4bojDnF33AZPUkg6yMlcwGpZObl8IzszjdTToGP032bhe"
    end

    twitter_data = get_twitter_data_from_spreadsheets(twitter_client, spreadsheets)

    Tweet.add_tweets_to_db(twitter_data)
    # @tweets = Tweet.pending.order(users_followers: :desc)
    @tweets = Tweet.pending
    render :index
  end

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

  def get_twitter_data_from_spreadsheets(twitter_client, spreadsheets)
    ids = get_column_data(spreadsheets, 4).uniq
    start_index = 0
    end_index = 100
    twitter_data = []
    new_ids = ids - Tweet.pluck(:twitter_id)
    while start_index < new_ids.length
      bucket_of_ids = new_ids[start_index...end_index]
      twitter_data.concat(fetch_tweets_bucket(twitter_client, bucket_of_ids))
      start_index += 100
      end_index += 100
    end

    return twitter_data
  end

  def mark_property(column, id)
    tweet = Tweet.find(id)
    tweet.update({column => true})
    tweet.save
    @tweets = Tweet.pending
    render :index
  end

  def get_column_data(spreadsheets, column_number)
    column_data = []
    spreadsheets.each do |spreadsheet|
      worksheet = spreadsheet.worksheets[0]
      column_data.concat(get_ids_in_column(worksheet, column_number))
    end
    return column_data
  end

  def get_ids_in_column(worksheet, column_number)
    (1..worksheet.num_rows).to_a.map do |row_number|
      tweet_url = worksheet[row_number, column_number]
      Tweet.convert_url_to_id(tweet_url)
    end
  end

  # Only for one bucket of up to 100 ids. ids must be strings
  def fetch_tweets_bucket(client, ids)
    ids_string = ids.join(',')
    request_options = {id: ids_string}
    twitter_request = Twitter::REST::Request.new(client, :get, "1.1/statuses/lookup.json",  request_options)
    twitter_request.perform
  end

end


