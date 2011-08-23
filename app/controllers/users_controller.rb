class UsersController < ApplicationController
  def new
    @user = User.new
$stderr.puts @user.inspect
  end
  
  def create
    @user = User.new(params[:user])
    if @user.save!
      flash[:notice] = "Thank you for signing up! You are now logged in."
      redirect_to "/"
    else
      render :action => 'new'
    end
  end
end
