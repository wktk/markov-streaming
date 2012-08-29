# coding: utf-8

require 'net/http'
require 'rexml/document'
require 'okura/serializer'

class Markov
  def initialize(statuses, user)
    @user      = user
    @sentences = []
    @statuses  = []
    @tagger    = Okura::Serializer::FormatInfo.create_tagger 'naist-jdic'
    statuses.each { |status| self.add(status, true) }
  end
  
  def add(status, init = false)
    status.source.gsub!(/<[^>]+>/, '')
    if !status.user.protected && status.user.id != @user.id &&
       (!status.in_reply_to_user_id || status.in_reply_to_user_id == @user.id) &&
       ![ 'twittbot.net', 'EasyBotter', 'Easybotter', 'ツイ助。', 'MySweetBot', 'BotMaker' ].index(status.source)
      status.text.gsub!(/[　\s]*(?:[@＠#＃]\w+|殺|https?:\/\/t.co\/\w+|[rqｒｑＲＱ][tｔＴ].*)/im, '')
      return if status.text.gsub(/[　\s]/, '').empty?
      @statuses.push(status.text)
      @sentences.push(self.split(status.text))
      return if init
      @statuses.shift
      @sentences.shift
    end
  end
  
  def get
    dictionary = Hash.new([].freeze)
    @sentences.each do |words|
      prev = '[[START]]'
      words.each { |word| dictionary[prev] += [prev = word] }
      dictionary[prev] += ['[[END]]']
    end
    return dictionary
  end
  
  def create(dictionary = self.get, statuses = @statuses)
    text = ''
    for i in 1..50
      text = ''
      word = '[[START]]'
      while true
        word = dictionary[word].sample
        break if word == '[[END]]'
        text += word
      end
      return text if !statuses.index(text)
    end
    return text
  end
  
  protected
  def split(text)
    words = []
    @tagger.parse(text).mincost_path.each{ |node|
      words.push node.word.surface if node.word.surface != "BOS/EOS"
    }
    return words
  end
end
