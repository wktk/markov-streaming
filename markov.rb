# -*- coding: utf-8 -*-

require 'okura/serializer'

class Markov
  attr_reader :splited, :original

  def initialize(texts = {}, max_size = 30)
    @text_ids = []
    @original = {}
    @splited = {}
    @max_size = max_size
    @tagger = Okura::Serializer::FormatInfo.create_tagger 'naist-jdic'
    texts.each { |text| add(*text) }
  end

  def add(text, id)
    words = @tagger.wakati(text)
    return false if words.length < 6

    @text_ids.push(id.to_s)
    @splited[id.to_s] = words
    @original[id.to_s] = text

    if @text_ids.size > @max_size
      delete(@text_ids.shift)
    end
  end

  def delete(id)
    @splited.delete(id.to_s)
    @original.delete(id.to_s)
  end

  def get_table
    table = Hash.new([].freeze)
    @splited.values.each do |words|
      words = words.clone
      prev = words.shift
      words.each { |word| table[prev] += [prev = word] }
    end
    table
  end

  def create(table = get_table, original = @original.values)
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
