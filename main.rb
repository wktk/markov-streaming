# -*- coding: utf-8 -*-

require 'twitter'
require 'user_stream'
require './markov'

def puts(*args)
  STDERR.puts(*args)
end

def check_status(status)
  status.source.gsub!(/<[^>]+>/, '')
  status.text.gsub!(/&(?:amp|[gl]t);/, '&amp;' => '&', '&gt;' => '>', '&lt;' => '<')
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

  [status.text, status.id]
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
@markov = Markov.new(twitter.home_timeline(:count => 200).map { |status| check_status(status) }.compact.reverse)
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
  min_regexp = /#{ENV['MIN_REGEXP'] ? ENV['MIN_REGEXP'] : 25}/
  last = nil
  loop do
    sleep(1)
    now = Time.now
    if min_regexp =~ now.min.to_s && (last.nil? || last.hour != now.hour || last.min != now.min)
      begin
        message = @markov.create
        puts "Scheduled post at #{now.hour}:#{now.min}: #{message}"
        result = twitter.update(message)
      rescue => e
        puts "#{e.class} posting: #{e}"
        if e.to_s =~ /duplicate/
          count ||= 0
          count += 1
          retry if count < 10        
        end
      else
        puts "Posted: #{result.text}"
        last = now
      end
    end
  end
end

callback = Proc.new do |status|
  Thread.new do
    if status.text && status.user.id != @user.id
      if status.text =~ /[@＠]#{@user.screen_name}(?!\w)|^#{@user.name}へ。/ && status.text !~ /[rqｒｑＲＱ][tｔＴ]/i
        puts "Mention from @#{status.user.screen_name}: #{status.text}"
        begin
          message = "@#{status.user.screen_name} #{@markov.create}"[0...140]
          puts "Sending reply: #{message}"
          result = twitter.update(message, :in_reply_to_status_id => status.id)
        rescue => e
          puts "#{e.class} sending reply: #{e}"
          if e.to_s =~ /duplicate/
            count ||= 0
            count += 1
            retry if count < 10
          end
        else
          puts "Replied: #{result.text}"
        end
      end

      text = check_status(status)
      if text
        puts "Adding to table: @#{status.user.screen_name}: #{text[0]}"
        @markov.add(*text)
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
    elsif  status[:delete] && status[:delete].status
      puts "Deleted from table: #{@markov.delete(status[:delete].status.id_str)}"
    end
  end
end

loop do
  stream.user(:replies => :all, &callback)
  sleep(300)
end
