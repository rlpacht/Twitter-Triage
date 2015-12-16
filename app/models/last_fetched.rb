class LastFetched < ActiveRecord::Base

  def self.format_time
    if LastFetched.last.nil?
      return 0
    end
    t = LastFetched.last.last_fetched.localtime
    "#{t.month}/#{t.day}/#{t.year} at #{t.hour}:#{LastFetched.padded_minutes(t.min)}"
  end

  def self.padded_minutes(minutes)
    if minutes < 10
      return "0#{minutes}"
    else
      return minutes
    end
  end
end