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

twitter = Twitter.client(options)
stream  = UserStream.client(options)
@user   = twitter.verify_credentials
@markov = Markov.new

def get_text(status)
  status.source.gsub!(/<[^>]+>/, '')
  status.text.gsub!(/[@＠#＃]\w+|殺|https?:\/\/t.co\/\w+|[rqｒｑＲＱ][tｔＴ].*/im, '')
  status.text.strip!

  if false
    || status.user.protected
    || status.user.id == @user.id
    || status.text.empty?
    || (status.in_reply_to_user_id && status.in_reply_to_user_id != @user.id)
    || [
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

twitter.home_timeline(:count => 30).map { |status| get_text(status) }.compact.each { |status| add(status, true) }

loop do
  stream.user(:replies => 'all') do |status|
    if status.text && status.user.id != @user.id
      if status.text =~ /[@＠]#{@user.screen_name}(?!\w)|^#{@user.name}へ。/ && status.text !~ /[rqｒｑＲＱ][tｔＴ]/i
        begin
          twitter.update("@#{status.user.screen_name} #{@markov.create}"[0...140], :in_reply_to_status_id => status.id)
        rescue
        end
      end
      text = get_text(status)
      @markov.add_new(text) if text
    elsif status.event == 'follow' && status.target.id == @user.id
      begin
        # フォロー返し
        twitter.follow(status.source.screen_name)
      rescue
      end
    end
  end
  sleep(300)
end
