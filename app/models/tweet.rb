require 'redis/connection/hiredis'
require 'redis'

class Tweet
  attr_writer :text, :user
  attr_reader :id

  @@tweet_db = Redis.new

  def self.all
    @@tweet_db.setnx "tweets:counter", 0
    (0..@@tweet_db.get("tweets:counter").to_i).map do |id|
      Tweet.find id
    end
  end

  def initialize params={}
    params.each do |key, value|
      self.instance_variable_set ("@" + key.to_s).to_sym, value
    end
  end

  def text
    @text ||= @@tweet_db.get("tweet:#{@id}:text")
  end

  def user
    @user ||= User.find(@@tweet_db.get "tweet:#{@id}:user_id")
  end

  def save!
    @id ||= @@tweet_db.incr("tweets:counter")
    @@tweet_db.set "tweet:#{id}:text", text
    @@tweet_db.set "tweet:#{id}:user_id", user
    user.tweets << self
    user.save!
  end

  def self.find id
    Tweet.new({id: id})
  end

end
