require 'redis/connection/hiredis'
require 'redis'

class User

  include ActiveModel::Validations
  extend ActiveModel::Callbacks
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  attr_accessor :password, :password_confirmation
  attr_writer :username, :email
  attr_reader :id

  @@user_db = Redis.new

  define_model_callbacks :save

  before_save :prepare_password

  validates_presence_of :username

  # TODO - Right now this will overwrite your user if you re-use a username
  #validates_uniqueness_of :username, :email, :allow_blank => true
  validates_format_of :username, :with => /^[-\w\._@]+$/i, :allow_blank => true, :message => "should only contain letters, numbers, or .-_@"
  validates_format_of :email, :with => /^[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}$/i
  validate :check_password, :on =>:create

  def self.all
    @@user_db.setnx "users:counter", 0
    (0..@@user_db.get("users:counter").to_i).map do |id|
      User.find id
    end
  end

  def delete_tweets
    @@user_db.zremrangebyrank "user:#{@id}:tweets", 0, -1
    @tweets = []
  end

  def username
    @username ||= @@user_db.get("user:#{@id}:username")
  end

  def to_s
    @id
  end

  def email
    @email ||= @@user_db.get("user:#{@id}:email")
  end

  def tweets
    @tweets ||= @@user_db.zrange("user:#{@id}:tweets", 0, -1).map do |tweet_id|
      Tweet.find tweet_id
    end
  end

  def initialize params={}
    params.each do |key, value|
      self.instance_variable_set ("@" + key.to_s).to_sym, value
    end
  end

  def save!
    _run_save_callbacks do
      @id ||= @@user_db.incr("users:counter")
      @@user_db.set "user:#{id}:username", username
      @@user_db.set "username:#{username}", @id
      @@user_db.set "user:#{id}:email", email
      @@user_db.set "email:#{email}", @id
      @@user_db.set "user:#{id}:password_hash", password_hash
      @@user_db.set "user:#{id}:password_salt", password_salt
      tweets.each do |tweet|
        @@user_db.zadd "user:#{id}:tweets", tweet.id, tweet.id
      end
    end
  end

  def self.find id
    User.new({id: id})
  end

  def check_password
    if self.new_record?
      errors.add(:base, "Password can't be blank") if @password.blank?
      errors.add(:base, "Password and confirmation does not match") unless @password == @password_confirmation
      errors.add(:base, "Password must be at least 4 chars long") if @password.to_s.size.to_i < 4
    else
      if @password.blank?
        errors.add(:base, "Password can't be blank") if @password.blank?
      else
        errors.add(:base, "Password and confirmation does not match") unless @password == @password_confirmation
        errors.add(:base, "Password must be at least 4 chars long") if @password.to_s.size.to_i < 4
      end
    end
  end

  # login can be either username or email address
  def self.authenticate(login, pass)
    user_id = @@user_db.get("username:#{login}") || @@user_db.get("email:#{login}")
    user = find(user_id)
    return user if user && user.matching_password?(pass)
  end

  def matching_password?(pass)
    password_hash == encrypt_password(pass)
  end


  def followers
    # FIXME
    []
  end

  private

  def password_hash
    @password_hash ||= @@user_db.get("user:#{@id}:password_hash")
  end

  def password_salt
    @password_salt ||= @@user_db.get("user:#{@id}:password_salt")
  end

  def prepare_password
    unless @password.blank?
      @password_salt = Digest::SHA1.hexdigest([Time.now, rand].join)
      @password_hash = encrypt_password(@password)
    end
  end

  def encrypt_password(pass)
    Digest::SHA1.hexdigest([pass, password_salt].join)
  end

  def persisted?
    true
  end
end
