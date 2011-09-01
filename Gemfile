source 'http://rubygems.org'

gem 'rails', '3.0.9'
# gem 'pg'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'sqlite3-ruby', :require => 'sqlite3'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# Bundle the extra gems:
# gem 'bj'
# gem 'nokogiri', '1.4.1'
# gem 'sqlite3-ruby', :require => 'sqlite3'
# gem 'aws-s3', :require => 'aws/s3'

# Bundle gems for certain environments:
# gem 'rspec', :group => :test
# group :test do
#   gem 'webrat'
# end

gem "nifty-generators", :git => 'http://github.com/ryanb/nifty-generators.git'
gem "bcrypt-ruby", :require => "bcrypt"
gem "mocha", :group => :test

ENV['DB'] ||= "redis"

case ENV['DB'].downcase
  when "redis"
    gem "hiredis"
    gem "redis", :require => ["redis/connection/hiredis", "redis"]
  when 'mongo'
    gem "mongoid", "~> 2.1"
    gem "bson_ext", "~> 1.3"
  else
end