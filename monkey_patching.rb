module Enumerable
  def sum(&block)
    inject(0.0) { |memo, object| memo + (block.nil? ? object : block.call(object)) }.to_f
  end
end

class Array
  def average(&block)
    sum(&block) / length
  end
end

class Integer
  def odd?
    self % 2 == 1
  end

  def even?
    self % 2 == 0
  end
end

class Integer
  def to_bit_array(size)
    (0..(size - 1)).map { |i| self[i] }.reverse
  end
end
