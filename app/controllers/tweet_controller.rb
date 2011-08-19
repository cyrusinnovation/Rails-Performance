class TweetController < ApplicationController
  def new
    tmp = session[:user]
    if tmp
      @user = tmp
    else
      redirect_to login_path
    end
  end

  def create
    user = session[:user]
    Tweet.new(user, params[:tweets][:text]).save
    redirect_to '/tweet/new'
  end
end
