require "monkey_patching"
require "matrix"
require "name_options"

class Integer
  def to_signs_array(size)
    (0..(size - 1)).map { |i| self[i] == 0 ? -1 : 1 }.reverse
  end
  
  def sign
    self < 0 ? -1 : 1
  end
end

class Solver
  def initialize(categories, input_points)
    @categories = categories
    input_signs = 
      input_points.map do |point|
        [convert_to_signs(point[0]), point[1]]
      end
  
    @solve_result = {}
    input_signs.each do |signs, result|
      @solve_result[signs] = result
    end
    
    @weights = *input_signs.map { |x| Matrix.column_vector(x[0]) * Matrix.row_vector(x[0]) }.inject(Matrix.zero(matrix_size)) { |memo, object| memo + object }
    0.upto(matrix_size - 1) { |i| @weights[i][i] = 0 }
  end
  
  def test(point)
    neuron_inputs = convert_to_signs(point)
    next_temporary_point, temporary_point = neuron_inputs.map { |e| e.sign }, nil
    while temporary_point != next_temporary_point
      temporary_point = next_temporary_point
  
      neuron_inputs = 
        (0..(matrix_size - 1)).map do |i|
          (0..(matrix_size - 1)).sum do |j|
            (@weights[j][i] * temporary_point[j])
          end.to_i
        end
      next_temporary_point = neuron_inputs.map { |e| e.sign }
    end
    
    @solve_result[temporary_point]
  end
  
private
  def matrix_size
    @matrix_size ||= @categories.sum { |c| information_size(c) }
  end
  
  def information_size(category)
    (Math.log(category.length) / Math.log(2)).ceil
  end
  
  def convert_to_signs(point)
    bits = []
    point.each_with_index do |v, i|
      bits << @categories[i].index(v).to_signs_array(information_size(@categories[i]))
    end
    bits.flatten
  end
end

def analyse(group)
  name_options = NameOptions.new("#{group}.names")
  input_points = load_data("#{group}.data", name_options)
  test_points = load_data("#{group}.test", name_options)
  
  solver = Solver.new(name_options.categories, input_points)
  
  all = test_points.length
  matches = 0
  test_points.each do |point, original_result|
    result = solver.test(point)
    matches += 1 if result == original_result
  end
  
  puts "ALL TESTS: #{all}"
  puts "MATCHES: #{matches}"
  puts "NONMATCHES: #{all - matches}"
  puts "NONMATCHES%: #{(all - matches).to_f / all * 100}"
end

analyse("test")
