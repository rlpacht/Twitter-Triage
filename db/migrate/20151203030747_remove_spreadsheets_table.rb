class RemoveSpreadsheetsTable < ActiveRecord::Migration
  def change
    drop_table(:spreadsheets)
  end
end
