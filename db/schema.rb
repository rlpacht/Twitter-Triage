# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20151202190529) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "blacklists", force: :cascade do |t|
    t.string   "tweet_id"
    t.string   "string"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "spreadsheets", force: :cascade do |t|
    t.string   "id_str"
    t.string   "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tweets", force: :cascade do |t|
    t.string   "twitter_id"
    t.string   "tweet_text"
    t.string   "tweet_date"
    t.string   "tweet_time"
    t.integer  "retweet_count"
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.string   "tweet_link"
    t.string   "user"
    t.integer  "users_followers"
    t.boolean  "retweeted_status"
    t.boolean  "rejected",         default: false
    t.boolean  "done",             default: false
    t.boolean  "favorited",        default: false
  end

end
