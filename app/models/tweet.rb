require 'redis/connection/hiredis'
require 'redis'

class Tweet
  attr_writer :text, :user
  attr_reader :index

  @@tweet_db = Redis.new

  def self.all
    @@tweet_db.setnx "tweets:counter", 0
    [0..@@tweet_db.get("tweets:counter")].map do |index|
      Tweet.find index
    end
  end

  def initialize params
    params.each do |key, value|
      self.instance_variable_set key, value
    end
  end

  def text
    @text ||= @@tweet_db.get("tweet:#{@index}:text")
  end

  def user
    @user ||= User.find(@@tweet_db.get "tweet:#{@index}:user_id")
  end

  def save!
    @index ||= @@tweet_db.incr("tweets:counter")
    @@tweet_db.set "tweet:#{index}:text", text
    user.tweets << self
    user.save
  end

  def self.find index
    Tweet.new({index: index})
  end

end
