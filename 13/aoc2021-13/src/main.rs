use {
    std::{
        collections::{HashSet},
        str::FromStr,
        num::ParseIntError,
        fs::File,
        io::{prelude::*, BufReader},
        path::Path,
    },
};

#[derive(Debug, Copy, Clone, Eq, PartialEq, Hash)]
struct Point {
    x: i32,
    y: i32,
}

#[derive(Debug, Copy, Clone, Eq, PartialEq)]
enum Axis {
    Horizontal,
    Vertical,
}

#[derive(Debug, Copy, Clone, Eq, PartialEq)]
struct Fold {
    axis: Axis,
    value: i32,
}

impl Point {
    fn reflect_along(&self, fold: &Fold) -> Point {
        match fold.axis {
            Axis::Horizontal => Point{x: self.x, y: 2 * fold.value - self.y},
            Axis::Vertical => Point{x: 2 * fold.value - self.x, y: self.y},
        }
    }

    fn fold_along(&self, fold: &Fold) -> Point {
        match fold.axis {
            Axis::Horizontal => if self.y < fold.value { self.clone() } else { self.reflect_along(fold) },
            Axis::Vertical => if self.x < fold.value { self.clone() } else { self.reflect_along(fold) },
        }
    }
}

#[derive(Debug)]
struct ParseAxisError;
impl std::fmt::Display for ParseAxisError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result { write!(f, "Could not parse axis") }
}
impl std::error::Error for ParseAxisError{}

impl FromStr for Axis {
    type Err = ParseAxisError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "x" => Ok(Axis::Vertical),
            "y" => Ok(Axis::Horizontal),
            _ => Err(ParseAxisError),
        }
    }
}

impl FromStr for Point {
    type Err = ParseIntError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let coords: Vec<&str> = s.split(',').collect();
        let x = coords[0].parse::<i32>()?;
        let y = coords[1].parse::<i32>()?;
        Ok(Point { x, y })
    }
}

impl FromStr for Fold {
    type Err = ParseIntError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let split_strings: Vec<&str> = s
            .trim_start_matches("fold along ")
            .split('=').collect();
    
        let axis = split_strings[0].parse::<Axis>().unwrap();
        let value = split_strings[1].parse::<i32>().unwrap();

        Ok(Fold { axis, value })
    }
}

fn line_strings_from_file(filename: impl AsRef<Path>) -> Vec<String> {
    let file = File::open(filename).expect("No such file");
    let buf = BufReader::new(file);
    buf.lines()
        .map(|l| l.expect("Could not parse line"))
        .collect()
}

fn split_index(lines: &Vec<String>) -> usize {
    lines
        .iter()
        .enumerate()
        .find(|&r| r.1.to_string() == "".to_string())
        .unwrap()
        .0
}

fn split_at(v: &Vec<String>, i: usize) -> (Vec<String>, Vec<String>) {
    let n = v.len();
    assert!(i < n);
    (v[..i].to_vec(), v[i+1..].to_vec())
}

fn main() {
    let lines: Vec<String>  = line_strings_from_file("input.txt");

    let index: usize = split_index(&lines);
    let (point_strings, fold_strings) = split_at(&lines, index);
    let points: Vec<Point> = point_strings.iter().map(|s| Point::from_str(s).unwrap()).collect();
    let folds: Vec<Fold> = fold_strings.iter().map(|s| Fold::from_str(s).unwrap()).collect();

    let mut points_hash: HashSet<Point> = points.into_iter().collect();
    println!("{}", points_hash.len());

    for fold in &folds {
        points_hash = points_hash
            .iter()
            .map(|point| point.fold_along(fold))
            .collect();
    }

    print(&points_hash);
}

fn print(points: &HashSet<Point>) {
    let min_x = points.iter().min_by(|a, b| a.x.cmp(&b.x)).unwrap().x;
    let min_y = points.iter().min_by(|a, b| a.y.cmp(&b.y)).unwrap().y;
    let max_x = points.iter().max_by(|a, b| a.x.cmp(&b.x)).unwrap().x;
    let max_y = points.iter().max_by(|a, b| a.y.cmp(&b.y)).unwrap().y;

    for y in min_y..=max_y {
        let y_points: HashSet<Point> = points.clone().into_iter().filter(|&point| point.y == y).collect();
        let x_values: HashSet<i32> = y_points.iter().map(|&point| point.x).collect();
        let string: String = (min_x..=max_x).map(|x| if x_values.contains(&x) { "#" } else { "." }).collect();
        println!("{}", string);
    }
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn test_reflect() {
        assert_eq!(
            Point {x: 1, y: 2}.reflect_along(&Fold {axis: Axis::Horizontal, value: 4}),
            Point {x: 1, y: 6}
        );
        assert_eq!(
            Point {x: 1, y: -2}.reflect_along(&Fold {axis: Axis::Horizontal, value: 1}),
            Point {x: 1, y: 4}
        );
        assert_eq!(
            Point {x: 1, y: -2}.reflect_along(&Fold {axis: Axis::Vertical, value: 1}),
            Point {x: 1, y: -2}
        );
        assert_eq!(
            Point {x: 3, y: -2}.reflect_along(&Fold {axis: Axis::Vertical, value: -1}),
            Point {x: -5, y: -2}
        );
    }
}