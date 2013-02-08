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
@user   = twitter.verify_credentials
@markov = Markov.new

def add(status, init = false)
  # protected ユーザーを除外
  return if status.user.protected

  # 自分のツイートを除外
  return if status.user.id == @user.id

  # 他人宛ツイートを除外
  return if status.in_reply_to_user_id && status.in_reply_to_user_id != @user.id

  # bot などを除外
  status.source.gsub!(/<[^>]+>/, '')
  return if [
    'twittbot.net',
    'EasyBotter',
    'ツイ助。',
    'MySweetBot',
    'BotMaker'
  ].index(status.source)

  # ユーザー名、URL などを削除
  status.text.gsub!(/[@＠#＃]\w+|殺|https?:\/\/t.co\/\w+|[rqｒｑＲＱ][tｔＴ].*/im, '')

  # 前後の空白を削除
  status.text.strip!

  @markov.add(status.text, init) if !status.text.empty?
end

twitter.home_timeline(:count => 30).each { |status| add(status, true) }

loop do
  stream.user(:replies => 'all') do |status|
    if status.text && status.user.id != @user.id
      if status.text =~ /[@＠]#{@user.screen_name}(?!\w)|^#{@user.name}へ。/ && status.text !~ /[rqｒｑＲＱ][tｔＴ]/i
        begin
          twitter.update("@#{status.user.screen_name} #{@markov.create}"[0...140], :in_reply_to_status_id => status.id)
        rescue
        end
      end
      add(status)
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
