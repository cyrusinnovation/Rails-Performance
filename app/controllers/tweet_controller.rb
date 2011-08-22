class TweetController < ApplicationController
  def new
    if !session[:user_id].blank?
      @user = User.find(cookies[:user_id])
      @listed_tweets = @user.tweets
    else
      redirect_to login_path
    end
  end

  def create
    user = User.find(cookies[:user_id])
    @tweet = Tweet.new(params[:tweet])
    @tweet.user = user
    @tweet.save!
    redirect_to '/tweet/new'
  end
end
