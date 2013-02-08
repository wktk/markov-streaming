# -*- coding: utf-8 -*-

require 'okura/serializer'

class Markov
  attr_reader :splited, :original

  def initialize(texts = [])
    @original = []
    @splited = []
    @tagger = Okura::Serializer::FormatInfo.create_tagger 'naist-jdic'
    texts.each { |text| add(text) }
  end

  def add(text)
    words = @tagger.wakati(text, nil)
    return false if words.length < 6
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
      prev = words.shift
      words.each { |word| table[prev] += [prev = word] }
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
