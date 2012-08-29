# coding: utf-8

require 'net/http'
require 'rexml/document'
require 'okura/serializer'

class Markov
  def initialize()
    @sentences = [] # 元の文章の記録用
    @statuses  = [] # 単語分割済み文章用
    @tagger    = Okura::Serializer::FormatInfo.create_tagger 'naist-jdic'
  end
  
  def add(text, init = false)
    @statuses.push(text)
    @sentences.push(self.split(text))
    
    # 昔のことは忘れる
    return if init
    @statuses.shift
    @sentences.shift
  end
  
  def dictionary
    dictionary = Hash.new([].freeze)
    @sentences.each do |words|
      prev = '[[START]]'
      words.each { |word| dictionary[prev] += [prev = word] }
      dictionary[prev] += ['[[END]]']
    end
    return dictionary
  end
  
  def create(dictionary = self.dictionary, statuses = @statuses)
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
    return ''
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
