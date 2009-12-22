require "monkey_patching"

class PotentialFunction
  def initialize(lambda)
    @lambda = lambda
  end

  def execute(x, y)
    distance = Math.sqrt x.zip(y).map{ |x, y| (x - y) ** 2 }.sum
    1.0 / (1.0 + @lambda * distance)
  end
end

class SecondPotentialFunction
  def initialize(lambda)
    @lambda = lambda
  end

  def execute(x, y)
    distance = x.zip(y).map{ |x, y| (x - y) ** 2 }.sum
    Math.exp(- @lambda * distance)
  end
end

class Solver
  def initialize(function, first, second)
    @function = function
    @points = []
    @first = first
    @second = second
  end
  
  def test(x)
    return @first if @points.empty?
    result = @points.sum { |r, point| r * @function.execute(x, point) }
    result > 0 ? @first : @second
  end
  
  def train(x, original_result)
    result = test(x)

    if result == @first and original_result == @second
      add(-1, x)
      on_change
    elsif result == @second and original_result == @first
      add(1, x)
      on_change
    else
      on_match
    end
  end
  
  def train_all(training_data)
    training_data.each do |point, result|
      train(point, result)
    end
  end

protected
  def on_change
  end

  def on_match
  end
  
private
  def add(r, point)
    @points << [r, point]
  end
end

class SuperSolver < Solver
  def initialize(function, first, second)
    super

    @current_change = 0
    @matches_since_last_change = 0
    @matches_since_last_change_needed = 0xFFFFFFFF
  end
  
  def train_all(training_data)
    i = 0
    while true
      point, result = training_data[i]
      train(point, result)
      break if @matches_since_last_change >= @matches_since_last_change_needed
      i += 1
      i = 0 if i == training_data.length
    end
  end
  
protected
  def on_change
    @current_change += 1
    @matches_since_last_change_needed = matches_needed(@current_change)
    @matches_since_last_change = 0
  end

  def on_match
    @matches_since_last_change += 1
  end

private
  def matches_needed(change)
    eps = 0.05
    nu = 0.9
    max_i = 1000
    n = 3
    @sum ||= (1..max_i).inject(0.0) { |sum, i| sum + 1.0 / (i ** n) }

    ((Math.log(nu) - Math.log(@sum) - n * Math.log(change)) / Math.log(1.0 - eps)).to_i
  end
end

class NameOptions
  attr_reader :columns, :result_values

  def initialize(filename)
    @columns = []
    @result_values = nil
    
    File.open(filename, "r") do |file|
      file.each do |line|
        process_line(line)
      end
    end
    
  end
  
private
  def process_line(line)
    if position = (/\|/ =~ line)
      line = line[0, position]
    end
    line.strip!
    
    if /:/ =~ line
      name, type = line.split(":").map { |part| part.gsub(/\./, "").strip }
      @columns << (type == "continuous" ? true : false)
    elsif not line.empty?
      @result_values = line.split(",").map { |part| part.gsub(/\./, "").strip }
    end
  end
end

def load_data(filename, name_options)
  points = []
  File.open(filename, "r") do |file|
    file.each do |line|
      point = line.strip.split(',').map { |part| part.strip }
      result = point.pop
      point = point.zip(name_options.columns).select { |value, use| use }.map { |value, use| value.to_f }
      points << [point, result]
    end
  end
  points
end

def normalize_options(points)
  length = points.first.first.length
  max_values = Array.new(length)
  min_values = Array.new(length)
  
  points.each do |point, result|
    point.each_with_index do |v, i|
      if max_values[i].nil? || v > max_values[i]
        max_values[i] = v
      end
      
      if min_values[i].nil? || v < min_values[i]
        min_values[i] = v
      end
    end
  end
  
  [max_values, min_values]
end

def normalize(points, max_values, min_values)
  points.map do |point, result|
    p = []
    point.each_with_index do |v, i|
      p << (v - min_values[i]) / (max_values[i] - min_values[i])
    end
    [p, result]
  end
end

def analyze(group, lambda)
  name_options = NameOptions.new("#{group}.names")
  input_points = load_data("#{group}.data", name_options)
  test_points = load_data("#{group}.test", name_options)
  
  max_values, min_values = normalize_options(input_points + test_points)
  
  input_points = normalize(input_points, max_values, min_values)
  test_points = normalize(test_points, max_values, min_values)
  
  # File.open("new_#{group}.data", "w+") do |file|
  #   input_points.each do |point, result|
  #     file.puts "#{point.join(", ")}, #{result}"
  #   end
  # end
  # 
  # File.open("new_#{group}.test", "w+") do |file|
  #   test_points.each do |point, result|
  #     file.puts "#{point.join(", ")}, #{result}"
  #   end
  # end
  
  
  # puts input_points.inspect
  
  solver = Solver.new(PotentialFunction.new(lambda), *name_options.result_values)
  solver.train_all(input_points)
  
  all = test_points.length
  matches = 0
  test_points.each do |point, original_result|
    result = solver.test(point)
    # puts "#{point.inspect} - #{result.inspect} - #{original_result.inspect}"
    matches += 1 if result == original_result
  end
  
  puts "ALL TESTS: #{all}"
  puts "MATCHES: #{matches}"
  puts "NONMATCHES: #{all - matches}"
  puts "NONMATCHES%: #{(all - matches).to_f / all * 100}"
end

analyze(ARGV[0] || "housing", (ARGV[1] || 0.1).to_f)
