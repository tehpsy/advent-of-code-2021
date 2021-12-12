from __future__ import annotations

chars = {'[': ']', '{': '}', '(': ')', '<': '>'}
invalid_syntax_scores = {']': 57, '}': 1197, ')': 3, '>': 25137}
completion_scores = {']': 2, '}': 3, ')': 1, '>': 4}

class Level:
    def __init__(self, char: str, parent: Level):
        self.char = char
        self.parent = parent
        self.levels = []

def is_open(char: str):
    return char in chars

def is_close(char: str):
    return char in chars.values()

def invalid_syntax_score_for_char(char: str):
    return invalid_syntax_scores.get(char, 0)

def invalid_syntax_score_for_line(line: str):
    root = Level(None, None)
    current_level = root
    for char in line:
        if is_open(char):
            new_level = Level(char, current_level)
            current_level.levels.append(new_level)
            current_level = new_level
        elif is_close(char):
            if char == chars[current_level.char]:
                current_level = current_level.parent
            else:
                return invalid_syntax_score_for_char(char)
    return 0

def total_invalid_syntax_score(lines: list) -> int:
    return sum(list(map(lambda line: invalid_syntax_score_for_line(line), lines)))

def completion_characters_for_line(line: str):
    root = Level(None, None)
    current_level = root
    for char in line:
        if is_open(char):
            new_level = Level(char, current_level)
            current_level.levels.append(new_level)
            current_level = new_level
        elif is_close(char):
            if char == chars[current_level.char]:
                current_level = current_level.parent
            else:
                raise 'Invalid'

    string = ""
    while (current_level is not root):
        string = string + chars[current_level.char]
        current_level = current_level.parent

    return string 

def completion_score(completion_chars: str):
    score = 0
    for char in completion_chars:
        score = score * 5 + completion_scores[char]
    return score

def total_completion_score(lines: list) -> int:
    incomplete_lines = list(filter(lambda line: invalid_syntax_score_for_line(line) == 0, lines))
    strings = list(map(lambda line: completion_characters_for_line(line), incomplete_lines))
    halfway_index = int(len(strings)/2)
    return sorted(list(map(lambda string: completion_score(string), strings)))[halfway_index]

if __name__ == '__main__':
    with open('input.txt') as f:
        lines = f.read().split('\n')
        print('Invalid syntax score: ' + str(total_invalid_syntax_score(lines)))
        print('Completion score: ' + str(total_completion_score(lines)))
