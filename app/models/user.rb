class User

  include Mongoid::Document

  attr_accessor :password, :password_confirmation

  field :username,        :type => String
  field :email,           :type => String
  field :password_hash,   :type => String
  field :password_salt,   :type => String

  before_save :prepare_password

  validates_presence_of :username
  validates_uniqueness_of :username, :email, :allow_blank => true
  validates_format_of :username, :with => /^[-\w\._@]+$/i, :allow_blank => true, :message => "should only contain letters, numbers, or .-_@"
  validates_format_of :email, :with => /^[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}$/i
  validate :check_password

  def check_password
    if self.new_record?
      errors.add(:base, "Password can't be blank") if self.password.blank?
      errors.add(:base, "Password and confirmation does not match") unless self.password == self.password_confirmation
      errors.add(:base, "Password must be at least 4 chars long") if self.password.to_s.size.to_i < 4
    else
      if self.password.blank?
        errors.add(:base, "Password can't be blank") if self.password.blank?
      else
        errors.add(:base, "Password and confirmation does not match") unless self.password == self.password_confirmation
        errors.add(:base, "Password must be at least 4 chars long") if self.password.to_s.size.to_i < 4
      end
    end
  end

  # login can be either username or email address
  def self.authenticate(login, pass)
    user = first(:conditions => {:username => login}) || first(:conditions => {:email => login})
    return user if user && user.matching_password?(pass)
  end

  def matching_password?(pass)
    self.password_hash == encrypt_password(pass)
  end


  def followers
    # FIXME
    []
  end

  private

  def prepare_password
    unless password.blank?
      self.password_salt = Digest::SHA1.hexdigest([Time.now, rand].join)
      self.password_hash = encrypt_password(password)
    end
  end

  def encrypt_password(pass)
    Digest::SHA1.hexdigest([pass, password_salt].join)
  end

  after_create do
    File.open("#{RAILS_ROOT}/public/#{self.username}.js", 'w') {|io|
      io.puts 'timeline(['
      io.puts ']);'
    }
  end

end
