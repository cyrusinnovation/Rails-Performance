require "test_helper"

class TweetTest < ActiveSupport::TestCase

  def setup
    @user = User.new(username:"test_user", email:"pblair@ci.com", password:"foobar", password_confirmation:"foobar")
    @user.save!
  end

  test "create a tweet" do
    assert_difference "Tweet.count", 1 do
      tweet = Tweet.new({text: "test tweet"})
      tweet.save!
      assert_equal "test tweet", tweet.text
    end
  end

  test "create a tweet with a user" do
    assert_difference "Tweet.count", 1 do
      tweet = Tweet.new({text: "tweet with user", user: @user})
      tweet.save!
      saved = Tweet.find(tweet.id)
      assert_equal @user.id, saved.user.id
    end
  end

  test "tweet with user saves user's tweets" do
    assert_difference "@user.tweets.count", 1 do
      tweet = Tweet.new({text: "tweet with user", user: @user})
      tweet.save!
    end
  end

  def teardown
    @user.delete
  end

end