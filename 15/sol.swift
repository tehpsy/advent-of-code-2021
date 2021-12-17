#!/usr/bin/env swift
import Foundation

enum Direction: CaseIterable {
  case up, down, left, right
}

struct Point: Hashable {
  let x: Int
  let y: Int

  func moving(direction: Direction) -> Point {
    switch direction {
      case .up: return Point(x: self.x, y: self.y - 1)
      case .down: return Point(x: self.x, y: self.y + 1)
      case .left: return Point(x: self.x - 1, y: self.y)
      case .right: return Point(x: self.x + 1, y: self.y)
    }
  }

  func neighbour(direction: Direction, numRows: Int, numColumns: Int) -> Point? {
    if direction == .up && y == 0 { return nil }
    if direction == .down && y == numRows - 1 { return nil }
    if direction == .left && x == 0 { return nil }
    if direction == .right && x == numColumns - 1 { return nil }
    return moving(direction: direction)
  }
}

class Node {
  let point: Point
  var nodes: [(Node, Cost)] = []
  var fromNode: Node?
  var value: Int?
  init(_ point: Point) {
    self.point = point
  }
}

class Queue {
  private var nodes: [Node]
  let endNode: Node

  init(_ nodes: [Node], _ endNode: Node) {
    self.nodes = nodes.sorted { n1, n2 in n1.value != nil }
    self.endNode = endNode
  }

  func popFirst() -> Node? {
    let next = self.nodes.first
    if !nodes.isEmpty {
      nodes.removeFirst()  
    }
    return next
  }

  func setValue(_ node: Node, _ fromNode: Node, _ value: Int) {
    node.value = value
    node.fromNode = fromNode

    let sourceIndex = nodes.firstIndex(where: { $0 === node })!
    let destinationIndex = nodes.firstIndex(where: { $0.value == nil || $0.value! >= value })!
    
    nodes.remove(at: sourceIndex)
    nodes.insert(node, at: destinationIndex)
  }
}

typealias Cost = Int
typealias Nodes = Set<Point>

if CommandLine.arguments.count > 1, CommandLine.arguments[1] == "--test" {
  runTests()
  run("input-test.txt")
} else {
  run("input.txt")
}

func run(_ filename: String) {
  let values = parse(filename, tiling: 5)
  let nodes = generate(from: values)
  let endNode = nodes.first(where: { $0.point == Point(x: values[0].count - 1, y: values.count - 1) })!
  process(nodes, endNode)
  print(endNode.value)
}

func process(_ nodes: [Node], _ endNode: Node) {
  let queue = Queue(nodes, endNode)
  var history = Set<Point>()

  while let node = queue.popFirst() {
    history.insert(node.point)
    node.nodes
      .filter { !history.contains($0.0.point) }
      .forEach { (nextNode, cost) in
        let newValue = cost + node.value!
        if nextNode.value == nil || newValue < nextNode.value! {
          queue.setValue(nextNode, node, newValue)
        }
      }

    if node === endNode { break }
  }
}

func parse(_ filename: String, tiling: Int = 1) -> [[Int]] {
  let path = FileManager.default.currentDirectoryPath.appending("/\(filename)")
  let string = try! String(contentsOfFile: path, encoding: String.Encoding.utf8)
  let lines = string.components(separatedBy: "\n").map { line in
    return line.map { Int(String($0))! }
  }

  var yValues: [[Int]] = []
  (0..<tiling).forEach { yTileIndex in
    lines.forEach { line in
      var xValues: [Int] = []
      (0..<tiling).forEach { xTileIndex in
        line.forEach { value in
          xValues.append(((value - 1) + yTileIndex + xTileIndex) % 9 + 1)
        }
        
      }
      yValues.append(xValues)
    }
  }

  return yValues
}

func generate(from values: [[Int]]) -> [Node] {
  var nodeMap: [Point: Node] = [:]

  values.enumerated().forEach { (yIndex, line) in
    line.enumerated().forEach { (xIndex, value) in
      let point = Point(x: xIndex, y: yIndex)
      nodeMap[point] = Node(point)
    }
  }

  nodeMap.forEach { (point, node) in
    node.nodes = Direction.allCases.compactMap { direction in
      guard let neighbourPoint = point.neighbour(direction: direction, numRows: values.count, numColumns: values[0].count) else { return nil }
      let cost = values[neighbourPoint.y][neighbourPoint.x]
      let neighbourNode = nodeMap[neighbourPoint]!
      return (neighbourNode, cost)
    }
  }

  nodeMap[Point(x: 0, y: 0)]!.value = 0

  return Array(nodeMap.values)
}
// /* TESTS */

func runTests() {
  testBuild() 
}

extension Array where Element: Node {
  func sort() -> [Node] {
    return self.sorted { n1, n2 in
      if n1.point.y != n2.point.y {
        return n1.point.y < n2.point.y
      }
      return n1.point.x < n2.point.x
    }
  }
}

func testBuild() {
  let nodes = generate(from: [[1, 1, 6], [2, 3, 8]]).sort()
  assert(nodes.count == 6)
  assert(nodes[0].nodes.count == 2)
  assert(nodes[1].nodes.count == 3)
  assert(nodes[2].nodes.count == 2)
  assert(nodes[3].nodes.count == 2)
  assert(nodes[4].nodes.count == 3)
  assert(nodes[5].nodes.count == 2)
}