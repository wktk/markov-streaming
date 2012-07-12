#!/usr/bin/env ruby
# coding: utf-8

require 'twitter'
require 'user_stream'
require './markov'

options = {
  :consumer_key       => ENV['CONSUMER_KEY'],
  :consumer_secret    => ENV['CONSUMER_SECRET'],
  :oauth_token        => ENV['ACCESS_TOKEN'],
  :oauth_token_secret => ENV['ACCESS_TOKEN_SECRET'],
}

twitter = Twitter.new(options)
stream  = UserStream.client(options)
user    = twitter.verify_credentials
markov  = Markov.new(ENV['APPID'], twitter.home_timeline(:count => 30), user)

loop do
  stream.user(:replies => 'all') do |status|
    if status.text && status.user.id != user.id
      if status.text =~ /[@＠]#{user.screen_name}(?!\w)/ && status.text !~ /[rqｒｑＲＱ][tｔＴ]/i
        begin
          twitter.update("@#{status.user.screen_name} #{markov.create}"[0...140], :in_reply_to_status_id => status.id)
        rescue
        end
      end
      markov.add(status)
    elsif status.event == 'follow' && status.target.id == user.id
      begin
        twitter.follow(status.source.screen_name)
      rescue
      end
    end
  end
  sleep(30)
end
