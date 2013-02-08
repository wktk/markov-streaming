# -*- coding: utf-8 -*-

require 'twitter'
require 'user_stream'
require './markov'

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

options = {
  :consumer_key       => ENV['CONSUMER_KEY'],
  :consumer_secret    => ENV['CONSUMER_SECRET'],
  :oauth_token        => ENV['ACCESS_TOKEN'],
  :oauth_token_secret => ENV['ACCESS_TOKEN_SECRET'],
}

twitter = Twitter::Client.new(options)
stream = UserStream::Client.new(options)
@user = twitter.verify_credentials
@markov = Markov.new(twitter.home_timeline(:count => 200).map { |status| get_text(status) }.compact[0...30])
puts "Ready (Bot: @#{@user.screen_name})"

Thread.abort_on_exception = true

Thread.new do
  friends = []
  cursor = -1
  while cursor.nonzero?
    result = twitter.friend_ids(@user, :cursor => cursor)
    cursor = result.next_cursor
    friends.push(*result.ids)
  end

  followers = []
  cursor = -1
  while cursor.nonzero?
    result = twitter.follower_ids(@user, :cursor => cursor)
    cursor = result.next_cursor
    followers.push(*result.ids)
  end

  unfollowers = friends - followers
  unless unfollowers.empty?
    twitter.friendships(unfollowers).each do |user|
      next if user[:connections].include?('followed_by')
      puts "Unfollowed by @#{user.screen_name}.  Unfollowing..."
      begin
        twitter.unfollow(user)
      rescue => e
        puts "#{e.class} unfollowing @#{user.screen_name}: #{e}"
      else
        puts "Unfollowed @#{user.screen_name}"
      end
    end
  end

  new_followers = followers - friends
  unless new_followers.empty?
    twitter.friendships(new_followers).each do |user|
      next if user[:connections].include?('following')
      next if user[:connections].include?('following_requested')
      puts "Followed by @#{user.screen_name}.  Following back..."
      begin
        twitter.follow!(user)
      rescue  => e
        puts "#{e.class} following @#{user.screen_name}: #{e}"
      else
        puts "Followed @#{user.screen_name}"
      end
    end
  end
end

Thread.new do
  last = Time.at(0)
  loop do
    sleep(1)
    now = Time.now
    if now.min == 0 && last.hour == now.hour || last.year != now.year
      message = @markov.create
      puts "Scheduled post: #{message}"
      begin
        twitter.update(message)
      rescue => e
        puts "#{e.class} posting: #{e}"
      else
        puts "Posted."
        last = now
      end
    end
  end
end

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
        result = twitter.follow!(status.source.screen_name)[0]
      rescue => e
        puts "#{e.class} following @#{status.source.screen_name}: #{e}"
      else
        puts "Followed @#{result.screen_name}"
      end
    end
  end
  sleep(300)
end
