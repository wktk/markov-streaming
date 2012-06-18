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
  :screen_name        => ENV['SCREEN_NAME']
}

twitter = Twitter.new(options)
stream  = UserStream.client(options)
markov  = Markov.new(ENV['APPID'], twitter.home_timeline(:count => 30))

loop do
  stream.user(:replies => 'all') do |status|
    if status.text && status.user.screen_name != options[:screen_name]
      if status.text =~ /[@＠]#{options[:screen_name]}/
        begin
          twitter.update(("@#{status.user.screen_name} #{markov.create}").split[0...140].join,
                          :in_reply_to_status_id => status.id)
        rescue
        end
      end
      markov.add(status)
    elsif status.event == 'follow' && status.target.screen_name == options[:screen_name]
      begin
        twitter.follow(status.source.screen_name)
      rescue
      end
    end
  end
  sleep(30)
end
