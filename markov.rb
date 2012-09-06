# coding: utf-8

require 'net/http'
require 'okura/serializer'

class Markov
  def initialize
    @original_texts = []
    @splited_texts  = []
    @tagger         = Okura::Serializer::FormatInfo.create_tagger 'naist-jdic'
  end
  
  def add(text, init = false)
    words = self.split(text)
    return if words.length < 4  # 単語が少ないと連鎖しづらいのでスルー
    @original_texts.push(text)
    @splited_texts.push(words)
    
    # 昔のことは忘れる
    return if init
    @original_texts.shift
    @splited_texts.shift
  end
  
  def dictionary
    dictionary = Hash.new([].freeze)
    @splited_texts.each do |words|
      prev = '[[START]]'
      words.each { |word| dictionary[prev] += [prev = word] }
      dictionary[prev] += ['[[END]]']
    end
    return dictionary
  end
  
  def create(dictionary = self.dictionary, original_texts = @original_texts)
    for i in 1..50
      text = ''
      word = '[[START]]'
      loop do
        word = dictionary[word].sample
        break if word == '[[END]]'
        text += word
      end
      return text if !original_texts.index(text)
    end
    return ''
  end
  
  protected
  def split(text)
    words = @tagger.wakati(text, nil)
    words.delete('BOS/EOS')
    return words
  end
end
