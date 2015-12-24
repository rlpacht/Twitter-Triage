class BlacklistsController < ApplicationController
  protect_from_forgery :except => :create

  def create
    @blacklist = Blacklist.create(params[:tweet_data])
    render json: {blacklist: @blacklist}
  end
end
