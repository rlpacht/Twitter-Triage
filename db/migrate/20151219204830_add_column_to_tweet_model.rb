class AddColumnToTweetModel < ActiveRecord::Migration
  def change
    add_column :tweets, :non_url_text, :string
  end
end
