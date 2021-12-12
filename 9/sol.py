from __future__ import annotations
from enum import Enum
import math

class Direction(Enum):
  UP = 0
  DOWN = 1
  LEFT = 2
  RIGHT = 3

class Point:
    def __init__(self, x: int, y: int):
        self.x = x
        self.y = y

    def __repr__(self):
        return "<Point x:%s y:%s>" % (self.x, self.y)

    def __eq__(self, other):
        if isinstance(other, Point):
            return ((self.x == other.x) and (self.y == other.y))
        else:
            return False

    def __hash__(self):
        return hash(self.__repr__())

    def adjacent_point(self, direction: Direction) -> Point:
        if direction == Direction.UP:
            return Point(self.x, self.y - 1)
        elif direction == Direction.DOWN:
            return Point(self.x, self.y + 1)
        elif direction == Direction.LEFT:
            return Point(self.x - 1, self.y)
        elif direction == Direction.RIGHT:
            return Point(self.x + 1, self.y)

class Basin:
    def __init__(self):
        self.points = set()

    def contains(self, point: Point) -> bool:
        return point in self.points

class Grid:
    def __init__(self, input: str):
        split_input = input.split('\n')
        self.num_columns = len(split_input[0])
        self.num_rows = len(split_input)
        self.values = list(map(int, input.replace("\n", "")))

    def value_at(self, point: Point) -> int:
        if (point.x < 0 or point.x >= self.num_columns or point.y < 0 or point.y >= self.num_rows):
            return None
        
        index = point.x + point.y * self.num_columns
        return self.values[index]

    def values_adjacent_to(self, point: Point) -> list:
        values = []
        for direction in Direction:
            new_point = point.adjacent_point(direction)
            new_index = self.value_at(new_point)
            if new_index is not None:
                values.append(new_index)
        
        return values

    def is_low_point(self, point: Point) -> int:
        value = self.value_at(point)
        return (all(x > value for x in self.values_adjacent_to(point)))
        
    def low_points(self) -> list:
        low_points = []
        for x in range(self.num_columns):
            for y in range(self.num_rows):
                point = Point(x, y)
                if self.is_low_point(point):
                    low_points.append(point)
        return low_points

    def risk_level(self) -> int:
        low_points = self.low_points()
        values = list(map(lambda point: self.value_at(point) + 1, low_points))
        return sum(values)

    def basin_index_containing(self, point: Point, basins: list) -> int:
        for index, basin in enumerate(basins):
            if basin.contains(point):
                return index

        return None

    def basins(self) -> list:
        basins = []
        for y in range(self.num_rows):
            for x in range(self.num_columns):
                point = Point(x, y)
                if self.value_at(point) == 9:
                    continue 

                basin_up_index = self.basin_index_containing(point.adjacent_point(Direction.UP), basins)
                basin_left_index = self.basin_index_containing(point.adjacent_point(Direction.LEFT), basins)

                if basin_up_index is None and basin_left_index is None:
                    new_basin = Basin()
                    new_basin.points.add(point)
                    basins.append(new_basin)

                if basin_up_index is not None:
                    basins[basin_up_index].points.add(point)
                
                if basin_left_index is not None:
                    basins[basin_left_index].points.add(point)

                if (basin_up_index is not None) and (basin_left_index is not None) and (basin_up_index != basin_left_index):
                    basins[basin_left_index].points.update(basins[basin_up_index].points)
                    del basins[basin_up_index]

        return basins

if __name__ == '__main__':
    with open('input.txt') as f:
      grid = Grid(f.read())
      
      print("Part 1: " + str(grid.risk_level()))

      basins = grid.basins()
      largest_basins = sorted(list(map(lambda basin: len(basin.points), basins)), reverse=True)[:3]
      print("Part 2: " + str(math.prod(largest_basins)))