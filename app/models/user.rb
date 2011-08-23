require 'redis/connection/hiredis'
require 'redis'

class User

  include ActiveModel::Validations
  include ActiveModel::Callbacks
#  include Mongoid::Document
#  has_many :tweets

#  field :username,        :type => String
#  field :email,           :type => String
#  field :password_hash,   :type => String
#  field :password_salt,   :type => String

  attr_writer :username, :email, :password, :password_confirmation
  attr_reader :index

  @@user_db = Redis.new

  define_model_callbacks :save

  before_save :prepare_password

  validates_presence_of :username

  # TODO - Right now this will overwrite your user if you re-use a username
  #validates_uniqueness_of :username, :email, :allow_blank => true
  validates_format_of :username, :with => /^[-\w\._@]+$/i, :allow_blank => true, :message => "should only contain letters, numbers, or .-_@"
  validates_format_of :email, :with => /^[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}$/i
  validate :check_password, :on =>:create

  def username
    @username ||= @@user_db.get("user:#{@index}:username")
  end

  def email
    @email ||= @@user_db.get("user:#{@index}:email")
  end

  def tweets
    @tweets ||= @@user_db.smembers("user:#{@index}:tweets")
  end

  def initialize params
    params.each do |key, value|
      self.instance_variable_set key, value
    end
  end

  def save
    @index ||= @@user_db.incr("users:counter")
    @@user_db.set "user:#{index}:username", username
    @@user_db.set "username:#{username}", @index
    @@user_db.set "user:#{index}:email", email
    @@user_db.set "email:#{email}", @index
    @@user_db.set "user:#{index}:password_hash", password_hash
    @@user_db.set "user:#{index}:password_salt", password_salt
    tweets.each do |tweet|
      @@user_db.sadd "user:#{index}:tweets", tweet.index
    end
  end

  def self.find index
    User.new({index: index})
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
    @password_hash ||= @@user_db.get("user:#{@index}:password_hash")
  end

  def password_salt
    @password_salt ||= @@user_db.get("user:#{@index}:password_salt")
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

end
