require "test_helper"

class TweetTest < ActiveSupport::TestCase

  test "create a tweet" do
    assert_difference "Tweet.count", 1 do
      tweet = Tweet.new({text: "test tweet"})
      tweet.save!
      assert_equal "test tweet", tweet.text
    end
  end

  test "create a tweet with a user" do
    assert_difference "Tweet.count", 1 do
      tweet = Tweet.new({text: "tweet with user", user: User.find(1)})
      tweet.save!
      saved = Tweet.find(tweet.id)
      assert_equal "1", saved.user.id
    end
  end

end