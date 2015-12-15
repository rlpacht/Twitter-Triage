class CreateLastFetcheds < ActiveRecord::Migration
  def change
    create_table :last_fetcheds do |t|
      t.datetime :last_fetched

      t.timestamps null: false
    end
  end
end
