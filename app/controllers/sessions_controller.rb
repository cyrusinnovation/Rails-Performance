class SessionsController < ApplicationController
  def new
    @listed_tweets = Tweet.all
  end

  def create
    user = User.authenticate(params[:login], params[:password])
    if user
      cookies[:user_id] = user.id
      redirect_to_target_or_default root_url#, :notice => "Logged in successfully."
    else
      flash.now[:alert] = "Invalid login or password."
       @listed_tweets = Tweet.all
      render :new
    end
  end

  def destroy
    cookies[:user_id] = nil
    redirect_to root_url, :notice => "You have been logged out."
  end
end
