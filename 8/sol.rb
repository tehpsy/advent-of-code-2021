Display = Struct.new(:input, :output)
$characters = "abcdefg".chars

def split_char_sequence(string)
  return string.split(" ")
end

def split_line(string)
  return string.split(" | ")
end

def read_displays_from_file(path)
  return File.open(path).readlines
    .map { |line| line.split(" | ") }
    .map { |seq| Display.new(seq[0].split(" "), seq[1].split(" ")) }
end

def deduce_bef(input, cypher)
  $characters.each {|char|
    occurences = input.filter{|seq| seq.include?(char)}.length()
    case occurences
    when 4
      cypher['e'] = char
    when 6
      cypher['b'] = char
    when 9
      cypher['f'] = char
    end
  }
end

def deduce_c(input, cypher)
  exclusion_chars = "bef".chars.map {|char| cypher[char] }.join
  filtered_input = input.map { |seq| seq.gsub!( /[#{exclusion_chars}]/, '' ) }
  target_sequence = filtered_input.find {|seq| seq.length() == 1 }
  cypher['c'] = target_sequence[0]
end

def deduce_adg(input, cypher)
  exclusion_chars = "bcef".chars.map {|char| cypher[char] }.join
  input = input
    .map { |seq| seq.gsub!(/[#{exclusion_chars}]/, '' ) }
    .filter { |seq| seq && seq.length > 0 && seq.length < 3 } #Ignore input sequences whose characters correspond to all-on or all-off

  element_length_2 = input.find {|seq| seq.length == 2}
  element_length_1 = input.find {|seq| seq.length == 1 && element_length_2.include?(seq)}
  element_length_1_other = input.find {|seq| seq != element_length_2 && seq != element_length_1}

  cypher['a'] = element_length_1
  cypher['d'] = element_length_1_other
  cypher['g'] = element_length_2.gsub(/#{element_length_1}/, '')
end

def create_cypher(input)
  cypher = Hash.new
  deduce_bef(input, cypher)
  deduce_c(input, cypher)
  deduce_adg(input, cypher)
  return cypher
end

def decode(string, cypher)
  return string.chars.map {|char| cypher.find{|key, value| value == char}.first}
end

def integer_string_for(string)
  case string.sort!.join
  when 'abcefg' 
    return '0'
  when 'cf' 
    return '1'
  when 'acdeg' 
    return '2'
  when 'acdfg' 
    return '3'
  when 'bcdf' 
    return '4'
  when 'abdfg' 
    return '5'
  when 'abdefg' 
    return '6'
  when 'acf' 
    return '7'
  when 'abcdefg' 
    return '8'
  when 'abcdfg' 
    return '9'
  else
    raise "Undetermined character sequence #{string}"
  end
end

def decode_output(strings, cypher)
  return strings
    .map {|string| decode(string, cypher)}
    .map {|string| integer_string_for(string)}
    .join
    .to_i
end

def main()
  puts read_displays_from_file('./input.txt')
    .map {|display| 
      cypher = create_cypher(display.input)
      decode_output(display.output, cypher)
    }
  .sum
end

main()