class RemoveExtraBlacklistColumn < ActiveRecord::Migration
  def change
    remove_column(:blacklists, :string)
  end
end
