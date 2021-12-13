from __future__ import annotations
import copy

class Octopus:
    def __init__(self, energy: int, x: int, y: int):
        self.energy = energy
        self.x = x
        self.y = y
        self.flashed = False

class Grid:
    def __init__(self, input: str):
        split_input = input.split('\n')
        self.num_columns = len(split_input[0])
        self.num_rows = len(split_input)
        self.octopuses = []
        for (y, row) in enumerate(split_input):
            for (x, char) in enumerate(row):
                octopus = Octopus(int(char), x, y)
                self.octopuses.append(octopus)

    def reset_flash(self):
        for octopus in self.octopuses:
            octopus.flashed = False

    def reset_energy(self):
        for octopus in self.octopuses:
            if octopus.energy > 9:
                octopus.energy = 0

    def increment_energy(self, x_range: range, y_range: range):
        for x1 in x_range:
            for y1 in y_range:
                octopus = self.octopus_at(x1, y1)
                if octopus is not None:
                    octopus.energy += 1

    def flash(self, octopus: Octopus):
        octopus.flashed = True
        self.increment_energy(range(octopus.x-1, octopus.x+2), range(octopus.y-1, octopus.y+2))

    def octopus_at(self, x: int, y: int) -> int:
        index = self.__index_at(x, y)
        if index is None:
            return None
        return self.octopuses[index]

    def __index_at(self, x: int, y: int) -> int:
        if (x not in range(0, self.num_columns) or y not in range(0, self.num_rows)):
            return None
        return x + y * self.num_columns

    def octopuses_that_will_flash(self) -> list:
        return list(filter(lambda octopus: not octopus.flashed and octopus.energy > 9, self.octopuses))

    def process_flashes(self):
        while len(self.octopuses_that_will_flash()) > 0:
            octopuses = self.octopuses_that_will_flash()
            for octopus in octopuses:
                self.flash(octopus)

    def count_flashed(self) -> int:
        return len(list(filter(lambda octopus: octopus.flashed, self.octopuses)))

    def flash_in_sync(self) -> bool:
        return all(octopus.energy == 0 for octopus in self.octopuses)

def tick(grid: Grid) -> int:
    grid.reset_flash()
    grid.increment_energy(range(0, grid.num_columns), range(0, grid.num_rows))
    grid.process_flashes()
    grid.reset_energy()

def total_flashes(grid: Grid, steps: int):
    flash_count = 0
    for step in range(0, 100):
        tick(grid)
        flash_count += grid.count_flashed()
    return flash_count

def first_flash_in_sync(grid: Grid):
    tick_count = 0
    while True:
        tick_count += 1
        tick(grid)
        if grid.flash_in_sync():
              return tick_count
        
if __name__ == '__main__':
    with open('input-test.txt') as f:
        grid = Grid(f.read())
        print('Total flashes: ' + str(total_flashes(copy.deepcopy(grid), 100)))
        print('First synchronised flash: ' + str(first_flash_in_sync(copy.deepcopy(grid))))        