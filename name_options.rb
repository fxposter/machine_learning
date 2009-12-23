class NameOptions
  attr_reader :columns, :result_values, :categories

  def initialize(filename)
    @columns = []
    @categories = []
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
      unless ["continuous", "ignore"].include?(type)
        @categories << type.split(",").map { |part| part.strip }
        @columns << true
      else
        @columns << false
      end
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
      point = point.zip(name_options.columns).select { |value, use| use }.map { |value, use| value }
      points << [point, result]
    end
  end
  points
end

