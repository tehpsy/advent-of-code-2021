class FuelLookupTable
  def initialize()
    @values = [0, 1]
  end

  def get_value_for_distance(value)
    if value > (@values.length - 1)
      @values.push(get_value_for_distance(value-1) + value)
    end    
    @values[value]
  end
end

def positions_from_file(path)
  File.open(path, 'r') do |file|
    return file.read
      .split(",")
      .map(&:to_i)
      .sort!
  end
end

def compute_fuel(positions, source_position, fuel_lookup)
  return positions
    .map {|position| fuel_lookup.get_value_for_distance((position - source_position).abs) }
    .sum
end

def compute(positions, fuel_lookup)
  (positions.first...positions.last)
    .map {|source_position| compute_fuel(positions, source_position, fuel_lookup) }
    .min
end

def main()
  positions = positions_from_file('./input.txt')
  fuel_lookup = FuelLookupTable.new
  puts compute(positions, fuel_lookup)
end

main()