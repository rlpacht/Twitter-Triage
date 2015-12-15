class LastFetched < ActiveRecord::Base
  def self.padded_minutes(minutes)
    if minutes < 10
      return "0#{minutes}"
    else
      return minutes
    end
  end
end
