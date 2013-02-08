# -*- coding: utf-8 -*-

require 'okura/serializer'

class Markov
  def initialize(texts = [])
    @original = []
    @splited = []
    @tagger = Okura::Serializer::FormatInfo.create_tagger 'naist-jdic'
    texts.each { |text| add(text) }
  end

  def add(text)
    words = @tagger.wakati(text)
    return false if words.length < 4
    @splited.push(words)
    @original.push(text)
  end

  def add_new(text)
    add(text)
    @splited.shift
    @original.shift
  end

  def get_table
    table = Hash.new([].freeze)
    @splited.each do |words|
      prev = 'BOS/EOS'
      words.each { |word| table[prev].push(prev = word) }
      table[prev].push('BOS/EOS')
    end
    table
  end

  def create(table = get_table, original = @original)
    text = ''
    50.times do
      text = ''
      word = 'BOS/EOS'
      loop do
        word = table[word].sample
        break if 'BOS/EOS' == word
        text += word
      end
      break unless original.include?(text)
    end
    text
  end
end
