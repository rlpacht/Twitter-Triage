class CreateSpreadsheets < ActiveRecord::Migration
  def change
    create_table :spreadsheets do |t|
      t.string :id_str
      t.string :text
      t.timestamps null: false
    end
  end
end
