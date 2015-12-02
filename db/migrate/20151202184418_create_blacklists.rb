class CreateBlacklists < ActiveRecord::Migration
  def change
    create_table :blacklists do |t|
      t.string :tweet_id
      t.string :string

      t.timestamps null: false
    end
  end
end
