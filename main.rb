# -*- coding: utf-8 -*-

require 'twitter'
require 'user_stream'
require './markov'

options = {
  :consumer_key       => ENV['CONSUMER_KEY'],
  :consumer_secret    => ENV['CONSUMER_SECRET'],
  :oauth_token        => ENV['ACCESS_TOKEN'],
  :oauth_token_secret => ENV['ACCESS_TOKEN_SECRET'],
}

def puts(*args)
  STDERR.puts *args
end

def get_text(status)
  status.source.gsub!(/<[^>]+>/, '')
  status.text.gsub!(/[@＠#＃]\w+|殺|https?:\/\/t.co\/\w+|[rqｒｑＲＱ][tｔＴ].*/im, '')
  status.text.strip!

  if status.user.protected ||
    status.user.id == @user.id ||
    status.text.empty? ||
    (status.in_reply_to_user_id && status.in_reply_to_user_id != @user.id) ||
    [
      'twittbot.net',
      'EasyBotter',
      'ツイ助。',
      'MySweetBot',
      'BotMaker'
    ].include?(status.source)

    return nil
  end

  status.text
end

twitter = Twitter::Client.new(options)
stream = UserStream.client(options)
@user = twitter.verify_credentials
@markov = Markov.new(twitter.home_timeline(:count => 30).map { |status| get_text(status) }.compact)
puts "Ready (Bot: @#{@user.screen_name})"

loop do
  stream.user(:replies => 'all') do |status|
    if status.text && status.user.id != @user.id
      if status.text =~ /[@＠]#{@user.screen_name}(?!\w)|^#{@user.name}へ。/ && status.text !~ /[rqｒｑＲＱ][tｔＴ]/i
        puts "Mention from @#{status.user.screen_name}: #{status.text}"
        message = "@#{status.user.screen_name} #{@markov.create}"[0...140]
        puts "Sending reply: #{message}"
        begin
          result = twitter.update(message, :in_reply_to_status_id => status.id)
        rescue => e
          puts "#{e.class} sending reply: #{e}"
        else
          puts "Replied: #{result.text}"
        end
      end

      text = get_text(status)
      if text
        puts "Adding to markov-table: @#{status.user.screen_name}: #{text}"
        @markov.add_new(text)
      end
    elsif status.event == 'follow' && status.target.id == @user.id
      puts "Followed by @#{status.source.screen_name}.  Following back..."
      begin
        result = twitter.follow(status.source.screen_name)
      rescue => e
        puts "#{e.class} following @#{status.source.screen_name}: #{e}"
      else
        puts "Followed @#{result.screen_name}"
      end
    end
  end
  sleep(300)
end
