// use std::iter::Scan;

use {
    std::{
        // ptr,
        collections::{HashSet, HashMap},
        str::FromStr,
        num::ParseIntError,
        fs::File,
        io::{prelude::*, BufReader},
        path::Path,
    },
};

#[derive(Debug, Copy, Clone, Eq, PartialEq, Hash)]
struct Point {
    x: i32, y: i32, z: i32,
}

impl Point {
    fn squared_distance_to(&self, other: &Point) -> i32 {
        let dx = self.x - other.x;
        let dy = self.y - other.y;
        let dz = self.z - other.z;
        (dx * dx) + (dy * dy) + (dz * dz)
    }
}

impl FromStr for Point {
    type Err = ParseIntError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let coords: Vec<&str> = s.split(',').collect();
        let x = coords[0].parse::<i32>()?;
        let y = coords[1].parse::<i32>()?;
        let z = coords[2].parse::<i32>()?;
        Ok(Point { x, y, z })
    }
}

struct Scanner {
    id: usize,
    points: HashSet<Point>,
    fingerprints: HashSet<i32>,
    fingerprints_map: HashMap<i32, (Point, Point)>,
}

// impl Scanner {
//     fn new() -> Scanner {
//     }
// }

fn main() {
    let lines: Vec<String>  = line_strings_from_file("input-test.txt");
    let scanners = build_scanners(&lines);
    determine_overlap(&scanners);
}

fn line_strings_from_file(filename: impl AsRef<Path>) -> Vec<String> {
    let file = File::open(filename).expect("No such file");
    let buf = BufReader::new(file);
    buf.lines()
        .map(|l| l.expect("Could not parse line"))
        .collect()
}

fn line_break_indices(lines: &Vec<String>) -> Vec<usize> {
    lines
        .iter()
        .enumerate()
        .filter(|&r| r.1.to_string() == "".to_string())
        .map(|tuple| tuple.0)
        .collect::<Vec<usize>>()
}

fn split_indices(indices: &Vec<usize>) -> Vec<(usize, usize)> {
    indices
        .iter()
        .enumerate()
        .map(|(index, element)| {
            let previous = if index == 0 { 0 } else { indices[index-1] + 1 };
            (previous + 1, *element)
        })
        .collect::<Vec<(usize, usize)>>()
}

fn split(lines: &Vec<String>, indices: &Vec<usize>) -> Vec<Vec<String>> {
    let split_indices = split_indices(&indices);
    
    split_indices
        .iter()
        .map(|x| { lines[x.0..x.1].to_vec() })
        .collect::<Vec<Vec<String>>>()
}

fn build_scanners(lines: &Vec<String>) -> Vec<Scanner> {
    let line_break_indices: Vec<usize> = line_break_indices(&lines);    
    split(&lines, &line_break_indices)
        .iter()
        .enumerate()
        .map(|strings| build_scanner(strings.1, strings.0)).collect()
}

fn build_scanner(point_strings: &Vec<String>, id: usize) -> Scanner {
    let points: HashSet<Point> = point_strings.iter().map(|s| Point::from_str(s).unwrap()).collect();
    let fingerprints = build_fingerprints(&points);
    let fingerprints_map = HashMap::new();
    Scanner { points, id, fingerprints, fingerprints_map }
}

fn build_fingerprints(points: &HashSet<Point>) -> HashSet<i32> {
    let mut set = HashSet::<i32>::new();
    for p1 in points.iter() {
        for p2 in points.iter() {
            set.insert(p1.squared_distance_to(p2));
        }   
    }
    set
}

fn determine_overlap(scanners: &Vec<Scanner>) {
    for scanner1 in scanners.iter() {
        for scanner2 in scanners.iter() {
            if scanner1 as *const _ == scanner2 as *const _ { continue; }

            let mut overlap = HashSet::<i32>::new();
            for val in &scanner1.fingerprints {
                if scanner2.fingerprints.contains(&val) {
                    overlap.insert(*val);
                }
            }

            if overlap.len() >= 12 {
                println!("Overlap {} {}", scanner1.id, scanner2.id);
            }
        }   
    }
}