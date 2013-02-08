# coding: utf-8

require 'okura/serializer'

class Markov
  def initialize
    @original_texts = []
    @splited_texts = []
    @tagger = Okura::Serializer::FormatInfo.create_tagger 'naist-jdic'
  end

  def add(text, init = false)
    words = wakati(text)
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
      prev = 'BOS/EOS'
      words.each { |word| dictionary[prev] += [prev = word] }
      dictionary[prev] += ['BOS/EOS']
    end
    dictionary
  end

  def create(dictionary = self.dictionary, original_texts = @original_texts)
    for i in 1..50
      text = ''
      word = 'BOS/EOS'
      loop do
        word = dictionary[word].sample
        break if word == 'BOS/EOS'
        text += word
      end
      break if !original_texts.index(text)
    end
    text
  end

  def wakati(text)
    @tagger.wakati(text, nil)
  end
end
