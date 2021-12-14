require 'set'

:large
:small

class Cave
  attr_accessor :id
  attr_accessor :size
  attr_accessor :connections
  def initialize(id)
    @id = id
    @size = size_for(id)
    @connections = Set[]
  end
end

def size_for(id)
  return id.downcase == id ? :small : :large
end

def build_caves(path)
  caves = Hash.new
  File.open(path, 'r') do |file|
    file.read.split("\n").each do |line|
      ids = line.split("-")
      add_path(ids[0], ids[1], caves)
    end
    
  end
  return caves
end

def add_path(id1, id2, caves)
  caves[id1] = caves[id1] || Cave.new(id1)
  caves[id2] = caves[id2] || Cave.new(id2)
  caves[id1].connections.add(id2)
  caves[id2].connections.add(id1)
end

def routes_for(cave, caves, route, small_cave_exception_id)  
  route << cave.id
  return available_next_steps(cave, route, small_cave_exception_id).inject([route]) { |routes, id| 
    next_cave = caves[id]
    next_route = deep_copy(route)
    routes += routes_for(next_cave, caves, next_route, small_cave_exception_id)
  }
end

def deep_copy(route)
  return Marshal.load(Marshal.dump(route))
end

def available_next_steps(cave, route, small_cave_exception_id)  
  if cave.id == 'end'
    return []
  end
  disallowed_connections = route.select {|id| 
    size_for(id) == :small && 
    ((id == small_cave_exception_id && num_times_visited(id, route) > 1) || 
     (id != small_cave_exception_id && num_times_visited(id, route) > 0))  
  }
  return cave.connections.select {|id| !disallowed_connections.include?(id) }
end

def num_times_visited(cave_id, route)
  return route.select {|id| id == cave_id }.length
end

def small_cave_ids_to_repeat(caves)
  return caves.select {|id, cave|
    cave.size == :small && id != 'start' && id != 'end' 
  }.keys
end

def filter_complete_routes(routes)
  return routes.select {|route| route[-1] == 'end'}
end

def main()
  caves = build_caves('./input.txt')

  puts "Part 1: " + filter_complete_routes(routes_for(caves['start'], caves, [], '')).length.to_s

  puts "Part 2: " + small_cave_ids_to_repeat(caves).inject(Set[]) { |routes, id| 
    routes += filter_complete_routes(routes_for(caves['start'], caves, [], id))
  }.length.to_s
end

main()