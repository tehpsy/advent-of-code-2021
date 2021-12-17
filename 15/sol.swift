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

class QueueItem {
  let point: Point
  var fromPoint: Point!
  var value: UInt64
  init(point: Point, value: UInt64) {
    self.point = point
    self.value = value
  }
}

// class Queue {
//   private let items = [QueueItem]()

//   init(items: Set<QueueItem>) {
//     self.items = items
//   }

//   func value(for point: Point) {

//   }

//   func setValue(for point: Point, fromPoint: Point, value: Int) {

//   }
// }
typealias Queue = [QueueItem]
typealias Weight = UInt64
typealias NodeConnections = [Point: Weight]
typealias GraphConnections = [Point: NodeConnections]
typealias Nodes = Set<Point>

if CommandLine.arguments.count > 1, CommandLine.arguments[1] == "--test" {
  runTests()
  run("input-test.txt")
} else {
  run("input.txt")
}

func run(_ filename: String) {
  let values = parse(filename, tiling: 5)
  let (nodes, connections) = GraphGenerator().generate(from: values)
  var queue = makeQueue(nodes: nodes)
  var history = Nodes()
  var endQueueItem = queue.first(where: { $0.point == Point(x: values[0].count - 1, y: values.count - 1) })!
  // print(nodes.count)
  // print(connections.flatMap {$0}.count)
  // process(startPoint, connections, &history, &queue, &endQueueItem)
  // print(endQueueItem.value)
}

let startPoint = Point(x: 0, y: 0)


func makeQueue(nodes: Nodes) -> Queue {
  return nodes.map { point in
    return QueueItem(point: point, value: point == startPoint ? 0 : UInt64.max)
  }
}

func process(_ point: Point, _ graphConnections: GraphConnections, _ history: inout Nodes, _ queue: inout Queue, _ endQueueItem: inout QueueItem) {
  if history.contains(point) { return }
  let nodeConnections = graphConnections[point]!.filter { !history.contains($0.0) }
  let currentQueueItem = queue.first(where: { $0.point == point })!

  nodeConnections.forEach { (connectingPoint, value) in
    let connectingQueueItem = queue.first(where: { $0.point == connectingPoint })!
    let newValue = value + currentQueueItem.value
    if connectingQueueItem.value == UInt64.max || newValue < connectingQueueItem.value {
      connectingQueueItem.value = newValue
      connectingQueueItem.fromPoint = point
    }
  }

  history.insert(point)

  let nextPoints = queue
    .filter { $0.value != UInt64.max }
    .filter { (endQueueItem.value == UInt64.max) ? true : ($0.value < endQueueItem.value) }
    .filter { !history.contains($0.point) }
    .sorted { $0.value < $1.value }
    .map { $0.point }

  // print(nextPoints)

  nextPoints.forEach { point in
    process(point, graphConnections, &history, &queue, &endQueueItem)
  }
}

func parse(_ filename: String, tiling: UInt64 = 1) -> [[UInt64]] {
  let path = FileManager.default.currentDirectoryPath.appending("/\(filename)")
  let string = try! String(contentsOfFile: path, encoding: String.Encoding.utf8)
  // return (0..<tiling).map { yTileIndex in
  //   return string.components(separatedBy: "\n").map { line in
  //     return (0..<tiling).map { xTileIndex in
  //       return line.map { ((Int(String($0))! - 1) + yTileIndex + xTileIndex) % 9 + 1 }
  //     }.flatMap { $0 }
  //   }
  // }.flatMap { $0 }

  let values = string.components(separatedBy: "\n").map { line in
    return line.map { UInt64(String($0))! }
  }
  
  var foo: [[UInt64]] = []

  (UInt64(0)..<tiling).forEach { yTileIndex in
    values.forEach { line in
      var bar: [UInt64] = []
      (UInt64(0)..<tiling).forEach { xTileIndex in
        line.forEach { value in
          bar.append(((value - 1) + yTileIndex + xTileIndex) % 9 + 1)
        }
        
      }
      foo.append(bar)
    }
  }

  return foo
}

class GraphGenerator {
  private func parse(_ path: String) -> [[UInt64]] {
    let string = try! String(contentsOfFile: path, encoding: String.Encoding.utf8)
    return string.components(separatedBy: "\n").map { line in
      return line.map { UInt64(String($0))! }
    }
  }

  func generate(from values: [[UInt64]]) -> (Nodes, GraphConnections) {
    var nodes = Nodes()
    var graphConnections = GraphConnections()

    values.enumerated().forEach { (yIndex, line) in
      line.enumerated().forEach { (xIndex, value) in
        let point = Point(x: xIndex, y: yIndex)
        nodes.insert(point)

        var nodeConnections = NodeConnections()

        Direction.allCases.forEach { direction in
          if let neighbourPoint = point.neighbour(direction: direction, numRows: values.count, numColumns: line.count) {
            nodes.insert(neighbourPoint)
            nodeConnections[neighbourPoint] = values[neighbourPoint.y][neighbourPoint.x]
          }
        }

        graphConnections[point] = nodeConnections
      }
    }

    return (nodes, graphConnections)
  }
}

// /* TESTS */

func runTests() {
  testBuild() 
}

func testBuild() {
  let (nodes, connections) = GraphGenerator().generate(from: [[1, 1, 6], [2, 3, 8]])
  assert(nodes.count == 6)
  assert(connections[Point(x: 0, y: 0)] == [
    Point(x: 1, y: 0): 1,
    Point(x: 0, y: 1): 2,
  ])
  assert(connections[Point(x: 1, y: 0)] == [
    Point(x: 0, y: 0): 1,
    Point(x: 2, y: 0): 6,
    Point(x: 1, y: 1): 3,
  ])
  assert(connections[Point(x: 2, y: 0)] == [
    Point(x: 1, y: 0): 1,
    Point(x: 2, y: 1): 8,
  ])
  assert(connections[Point(x: 0, y: 1)] == [
    Point(x: 0, y: 0): 1,
    Point(x: 1, y: 1): 3,
  ])
  assert(connections[Point(x: 1, y: 1)] == [
    Point(x: 0, y: 1): 2,
    Point(x: 1, y: 0): 1,
    Point(x: 2, y: 1): 8,
  ])
  assert(connections[Point(x: 2, y: 1)] == [
    Point(x: 1, y: 1): 3,
    Point(x: 2, y: 0): 6,
  ])
}

// func testCompletedRowInBoard() {
//   let board = Board(rows: [
//     Row(cells: [Cell(value: 0, marked: false), Cell(value: 0, marked: false)]),
//     Row(cells: [Cell(value: 0, marked: true), Cell(value: 0, marked: true)]),
//   ])
//   if !board.isWinner { fatalError() }
  
//   print("\(#function) passed")
// }

// func testCompletedColumnInBoard() {
//   let board = Board(rows: [
//     Row(cells: [Cell(value: 0, marked: false), Cell(value: 0, marked: true)]),
//     Row(cells: [Cell(value: 0, marked: false), Cell(value: 0, marked: true)]),
//   ])
//   if !board.isWinner { fatalError() }
  
//   print("\(#function) passed")
// }

// func testCompletedDiagonalInBoard() {
//   let board = Board(rows: [
//     Row(cells: [Cell(value: 0, marked: true), Cell(value: 0, marked: false)]),
//     Row(cells: [Cell(value: 0, marked: false), Cell(value: 0, marked: true)]),
//   ])
//   if board.isWinner { fatalError() }
  
//   print("\(#function) passed")
// }

// func testMarkingValue() {
//   let board1 = Board(rows: [
//     Row(cells: [Cell(value: 1, marked: false), Cell(value: 2, marked: false)]),
//     Row(cells: [Cell(value: 3, marked: false), Cell(value: 4, marked: false)]),
//   ])
  
//   let board2 = board1.marking(1)
//   let expectedBoard2 = Board(rows: [
//     Row(cells: [Cell(value: 1, marked: true), Cell(value: 2, marked: false)]),
//     Row(cells: [Cell(value: 3, marked: false), Cell(value: 4, marked: false)]),
//   ])
//   if board2 != expectedBoard2 { fatalError() }
  
//   let board3 = board2.marking(0)
//   if board3 != expectedBoard2 { fatalError() }

//   let board4 = board3.marking(2)
//   let expectedBoard4 = Board(rows: [
//     Row(cells: [Cell(value: 1, marked: true), Cell(value: 2, marked: true)]),
//     Row(cells: [Cell(value: 3, marked: false), Cell(value: 4, marked: false)]),
//   ])
//   if board4 != expectedBoard4 { fatalError() }

//   let board5 = board4.marking(3)
//   let expectedBoard5 = Board(rows: [
//     Row(cells: [Cell(value: 1, marked: true), Cell(value: 2, marked: true)]),
//     Row(cells: [Cell(value: 3, marked: true), Cell(value: 4, marked: false)]),
//   ])
//   if board5 != expectedBoard5 { fatalError() }

//   let board6 = board5.marking(4)
//   let expectedBoard6 = Board(rows: [
//     Row(cells: [Cell(value: 1, marked: true), Cell(value: 2, marked: true)]),
//     Row(cells: [Cell(value: 3, marked: true), Cell(value: 4, marked: true)]),
//   ])
//   if board6 != expectedBoard6 { fatalError() }

//   print("\(#function) passed")
// }