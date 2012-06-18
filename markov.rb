# coding: utf-8

require 'net/http'
require 'rexml/document'

class Markov
  def initialize(appid, statuses)
    @appid = appid
    @sentences = []
    @statuses  = []
    statuses.each { |status| self.add(status, true) }
  end
  
  def add(status, init = false)
    status.source.gsub!(/<[^>]+>/, '')
    if (init || rand(3) == 0) &&
       status.user.protected != 'true' &&
      !status.text.slice('t.co') &&
      ![ 'twittbot.net',
         'EasyBotter',
         'Easybotter',
         'ツイ助。',
         'MySweetBot',
         'BotMaker' ].index(status.source) &&
       status.text.gsub!(/[　\s]*(?:[@＠#＃]\w+|殺)/, '') &&
       !status.text.empty?
      @statuses.push(status.text)
      @sentences.push(self.split(status.text))
      if !init
        @statuses.shift
        @sentences.shift
      end
    end
  end
  
  def get
    dictionary = Hash.new([].freeze)
    @sentences.each do |words|
      prev = '[[START]]'
      words.each { |word| dictionary[prev] += [prev = word] }
      dictionary[prev] += ['[[END]]']
    end
    dictionary
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
    http = Net::HTTP.new('jlp.yahooapis.jp')
    response = http.post('/MAService/V1/parse', "appid=#{@appid}&response=surface&sentence=#{text}")
    doc = REXML::Document.new(response.body)
    words = []
    doc.elements.each('ResultSet/ma_result/word_list/word/surface') { |word| words.push(word.text) }
    words
  end
end
