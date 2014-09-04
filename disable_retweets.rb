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
  no_retweet_ids = client.no_retweet_ids
  client.friends.to_a.reject { |f| no_retweet_ids.include?(f.id) }
end

puts "Found #{pending_disable.length} users to disable RTs from"

pending_disable.each do |friend|
  make_request do
    puts "Disabling retweets from @#{friend.screen_name}"
    client.friendship_update(friend, retweets: false)
  end
end

puts "All done."
