#!/usr/bin/env ruby
require 'twitter'

api_key             = ENV.fetch('TWITTER_API_KEY')
api_secret          = ENV.fetch('TWITTER_API_SECRET')
access_token        = ENV.fetch('TWITTER_ACCESS_TOKEN')
access_token_secret = ENV.fetch('TWITTER_ACCESS_TOKEN_SECRET')

client = Twitter::REST::Client.new do |config|
  config.consumer_key        = api_key
  config.consumer_secret     = api_secret
  config.access_token        = access_token
  config.access_token_secret = access_token_secret
end

def make_request(&block)
  begin
    return yield
  rescue Twitter::Error::TooManyRequests => error
    delay = error.rate_limit.reset_in + 1
    delay.times do |i|
      puts "Rate limited by Twitter, trying again in #{delay - i} seconds"
      sleep 1
    end
    retry
  end
end

pending_disable = make_request do
  Array.new.tap do |queue|
    no_retweet_ids = client.no_retweet_ids

    client.friends(skip_status: true, include_user_entities: false).each do |friend|
      if !no_retweet_ids.include?(friend.id)
        queue << friend
      end
    end
  end
end

pending_disable.each do |friend|
  make_request do
    puts "Disabling retweets from @#{friend.screen_name}"
    client.friendship_update(friend, retweets: false)
  end
end
