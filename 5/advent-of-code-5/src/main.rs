use std::{
    fs::File,
    io::{prelude::*, BufReader},
    path::Path,
    collections::HashSet,
    collections::HashMap,
};
use maplit::hashset;
use maplit::hashmap;

#[derive(Eq, PartialEq, Debug, Copy, Clone, Hash)]
struct Point {
    x: u16,
    y: u16,
}

impl Line {
    fn all_points(&self) -> HashSet<Point> {
        //THIS SUCKS 👎
        let min_x = std::cmp::min(self.start.x, self.end.x);
        let max_x = std::cmp::max(self.start.x, self.end.x);
        let min_y = std::cmp::min(self.start.y, self.end.y);
        let max_y = std::cmp::max(self.start.y, self.end.y);

        let mut points: HashSet<Point> = hashset!{};
        if min_x == max_x {
            for y in min_y..=max_y {
                points.insert(Point{x: min_x, y});
            }
        } else if min_y == max_y {
            for x in min_x..=max_x {
                points.insert(Point{x, y: min_y});
            }
        } else {
            let len = max_x - min_x + 1;
            for i in 0..len {
                let x = if self.end.x > self.start.x { self.start.x + i } else { self.start.x - i };
                let y = if self.end.y > self.start.y { self.start.y + i } else { self.start.y - i };
                points.insert(Point{x: x, y: y});
            }
        }

        points
    }
}

#[derive(Eq, PartialEq, Debug, Copy, Clone)]
struct Line {
    start: Point,
    end: Point,
}

#[derive(Eq, PartialEq)]
struct Board {
    lines: Vec<Line>
}

impl Board {
    fn point_map(&self) -> HashMap<Point, u16>{
        let all_hash_sets: Vec<HashSet<Point>> = self.lines.iter().map(|line| line.all_points()).collect();
        let mut point_map: HashMap<Point, u16> = hashmap!{};

        //THIS ALSO SUCKS 👎
        for hash_set in all_hash_sets {
            for point in hash_set {
                *point_map.entry(point).or_insert(0) += 1;
            }
        }

        point_map
    }
}

fn main() {
    let lines: Vec<Line>  = line_strings_from_file("input.txt")
        .iter()
        .map(|string| line_from_string(string.to_string()))
        .collect();
    
    let board = Board {lines};

    let min_point_count = 2;
    let point_map: Vec<Point> = board.point_map()
        .iter()
        .filter(|&(_, &v)| v >= min_point_count)
        .map(|(k, _)| k.clone())
        .collect();
    
    println!("Points with minimum count of {}: {}", min_point_count, point_map.len());
}

fn line_strings_from_file(filename: impl AsRef<Path>) -> Vec<String> {
    let file = File::open(filename).expect("No such file");
    let buf = BufReader::new(file);
    buf.lines()
        .map(|l| l.expect("Could not parse line"))
        .collect()
}

fn line_from_string(string: String) -> Line {
    let points: Vec<Point> = remove_whitespace(&string)
        .split("->")
        .map(|string| point_from_string(string.to_string()))
        .collect::<Vec<Point>>();
    let start = points[0];
    let end = points[1];
    Line {start, end}
}

fn point_from_string(string: String) -> Point {
    let values: Vec<u16> = remove_whitespace(&string)
        .split(',')
        .map(|string| string.parse::<u16>().unwrap())
        .collect::<Vec<u16>>();
    let x = values[0];
    let y = values[1];
    Point {x, y}
}

fn remove_whitespace(string: &str) -> String {
    string.split_whitespace().collect::<String>()
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn test_point_from_string() {
        assert_eq!(point_from_string("1,2".to_string()), Point {x: 1, y: 2});
        assert_eq!(point_from_string("02,1".to_string()), Point {x: 2, y: 1});
        assert_eq!(point_from_string("02, 1".to_string()), Point {x: 2, y: 1});
    }

    #[test]
    fn test_line_from_string() {
        assert_eq!(
            line_from_string("1,2 -> 4, 3".to_string()),
            Line {start: Point {x: 1, y: 2}, end: Point {x: 4, y: 3}}
        );
    }

    #[test]
    fn test_all_points() {
        assert_eq!(
            Line {start: Point{x: 2, y:3}, end: Point{x: 5, y:3}}.all_points(),
            hashset![
                Point{x: 2, y:3},
                Point{x: 3, y:3},
                Point{x: 4, y:3}, 
                Point{x: 5, y:3},
            ]
        );

        assert_eq!(
            Line {start: Point{x: 4, y:7}, end: Point{x: 4, y:5}}.all_points(),
            hashset![
                Point{x: 4, y:5},
                Point{x: 4, y:6},
                Point{x: 4, y:7},
            ]
        );
    }

    #[test]
    fn test_point_map() {
        let board = Board {lines: vec![
            Line {start: Point{x: 4, y:7}, end: Point{x: 4, y:5}},
            Line {start: Point{x: 4, y:6}, end: Point{x: 4, y:8}},
            Line {start: Point{x: 3, y:7}, end: Point{x: 5, y:7}},
        ]};
        assert_eq!(
            board.point_map(),
            hashmap![
                Point{x: 4, y: 5} => 1,
                Point{x: 4, y: 6} => 2,
                Point{x: 4, y: 7} => 3,
                Point{x: 4, y: 8} => 1,
                Point{x: 3, y: 7} => 1,
                Point{x: 5, y: 7} => 1,
            ]
        );
    }
}