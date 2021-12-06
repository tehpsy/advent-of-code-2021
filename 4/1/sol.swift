#!/usr/bin/env swift
import Foundation

struct Cell: Equatable {
  let value: Int
  let marked: Bool

  init(value: Int, marked: Bool = false) {
    self.value = value
    self.marked = marked
  }
}

struct Row: Equatable {
  let cells: [Cell]
  var isWinner: Bool { return cells.allSatisfy { $0.marked } }
  var sumOfUnmarked: Int { 
    cells
      .filter { !$0.marked }
      .map(\.value)
      .reduce(0, +) 
  }
}

struct Board: Equatable {
  let rows: [Row]
  private var columns: [Row] {
    guard !rows.isEmpty else { return [] }
    let columnCount = rows[0].cells.count
    return (0..<columnCount).map { index in
      let cells = rows.reduce(into: []) { accumulatingResult, row in
        accumulatingResult.append(row.cells[index])
      }
      return Row(cells: cells)
    }
  }

  var isWinner: Bool { 
    (rows + columns).contains { $0.isWinner }
  }
 
  var sumOfUnmarked: Int { 
    rows
      .map(\.sumOfUnmarked)
      .reduce(0, +) 
  }

  func marking(_ value: Int) -> Board {
    Board(rows: rows.map { row in
      Row(cells: row.cells.map { cell in
        Cell(value: cell.value, marked: cell.marked || cell.value == value)
      })
    })
  }
}

if CommandLine.arguments.count > 1, CommandLine.arguments[1] == "--test" {
  runTests()
  run("input-test.txt")
} else {
  run("input.txt")
}

func run(_ filename: String) {
  let path = FileManager.default.currentDirectoryPath.appending("/\(filename)")
  let (drawnNumbers, boards) = parseFile(at: path)
  print(processFirstWinner(drawnNumbers: drawnNumbers, boards: boards))
  print(processLastWinner(drawnNumbers: drawnNumbers, boards: boards))
}

func processFirstWinner(drawnNumbers: DrawnNumbers, boards: [Board]) -> Int {
  var runningBoards = boards
  for drawnNumber in drawnNumbers {
    runningBoards = runningBoards.map { $0.marking(drawnNumber) }
    if let winner = runningBoards.first(where: { $0.isWinner }) {
      return winner.sumOfUnmarked * drawnNumber
    }
  }

  fatalError("No winner")
}

func processLastWinner(drawnNumbers: DrawnNumbers, boards: [Board]) -> Int {
  var runningBoards = boards
  for drawnNumber in drawnNumbers {
    runningBoards = runningBoards
      .map { $0.marking(drawnNumber) }

    if runningBoards.count > 1 {
      runningBoards = runningBoards.filter { !$0.isWinner }
    } else {
      let finalBoard = runningBoards[0]
      if finalBoard.isWinner {
        return finalBoard.sumOfUnmarked * drawnNumber 
      }
    }
  }

  fatalError("No winner")
}

typealias DrawnNumbers = [Int]
func parseFile(at path: String) -> (DrawnNumbers, [Board]) {
  let string = try! String(contentsOfFile: path, encoding: String.Encoding.utf8)
  let lines = string.components(separatedBy: "\n")
  let drawnNumbers = drawnNumbers(from: lines)
  let boards = parseBoards(from: Array(lines[1..<lines.count]))
  return (drawnNumbers, boards)
}

func drawnNumbers(from lines: [String]) -> [Int] {
  lines[0]
    .components(separatedBy: ",")
    .compactMap { Int($0) }
}

func parseBoards(from lines: [String]) -> [Board] {
  let boardStringArrays = splitBoardStrings(from: lines)
  return boardStringArrays.map { parseBoard(from: $0)}
}

func splitBoardStrings(from lines: [String]) -> [[String]] {
  lines.reduce(into: [[String]]()) { arr, row in
    if arr.isEmpty || (row.isEmpty && !arr.last!.isEmpty) {
      arr.append([])
    }

    if !row.isEmpty {
      arr[arr.count - 1].append(row)
    }
  }
  .filter { !$0.isEmpty }
}

func parseBoard(from lines: [String]) -> Board {
  Board(rows: lines.map { line in
    let values = parseValues(from: line)
    return Row(cells: values.map { Cell(value: $0) })
  })
}

func parseValues(from line: String) -> [Int] {
  line.components(separatedBy: .whitespaces).compactMap { Int($0) }
}


/* TESTS */

func runTests() {
  testRowIsWinner() 
  testCompletedRowInBoard() 
  testCompletedColumnInBoard() 
  testCompletedDiagonalInBoard()
  testMarkingValue()
}

func testRowIsWinner() {
  let row = Row(cells: [Cell(value: 0, marked: true), Cell(value: 0, marked: true)])
  if !row.isWinner { fatalError() }
  
  print("\(#function) passed")
}

func testCompletedRowInBoard() {
  let board = Board(rows: [
    Row(cells: [Cell(value: 0, marked: false), Cell(value: 0, marked: false)]),
    Row(cells: [Cell(value: 0, marked: true), Cell(value: 0, marked: true)]),
  ])
  if !board.isWinner { fatalError() }
  
  print("\(#function) passed")
}

func testCompletedColumnInBoard() {
  let board = Board(rows: [
    Row(cells: [Cell(value: 0, marked: false), Cell(value: 0, marked: true)]),
    Row(cells: [Cell(value: 0, marked: false), Cell(value: 0, marked: true)]),
  ])
  if !board.isWinner { fatalError() }
  
  print("\(#function) passed")
}

func testCompletedDiagonalInBoard() {
  let board = Board(rows: [
    Row(cells: [Cell(value: 0, marked: true), Cell(value: 0, marked: false)]),
    Row(cells: [Cell(value: 0, marked: false), Cell(value: 0, marked: true)]),
  ])
  if board.isWinner { fatalError() }
  
  print("\(#function) passed")
}

func testMarkingValue() {
  let board1 = Board(rows: [
    Row(cells: [Cell(value: 1, marked: false), Cell(value: 2, marked: false)]),
    Row(cells: [Cell(value: 3, marked: false), Cell(value: 4, marked: false)]),
  ])
  
  let board2 = board1.marking(1)
  let expectedBoard2 = Board(rows: [
    Row(cells: [Cell(value: 1, marked: true), Cell(value: 2, marked: false)]),
    Row(cells: [Cell(value: 3, marked: false), Cell(value: 4, marked: false)]),
  ])
  if board2 != expectedBoard2 { fatalError() }
  
  let board3 = board2.marking(0)
  if board3 != expectedBoard2 { fatalError() }

  let board4 = board3.marking(2)
  let expectedBoard4 = Board(rows: [
    Row(cells: [Cell(value: 1, marked: true), Cell(value: 2, marked: true)]),
    Row(cells: [Cell(value: 3, marked: false), Cell(value: 4, marked: false)]),
  ])
  if board4 != expectedBoard4 { fatalError() }

  let board5 = board4.marking(3)
  let expectedBoard5 = Board(rows: [
    Row(cells: [Cell(value: 1, marked: true), Cell(value: 2, marked: true)]),
    Row(cells: [Cell(value: 3, marked: true), Cell(value: 4, marked: false)]),
  ])
  if board5 != expectedBoard5 { fatalError() }

  let board6 = board5.marking(4)
  let expectedBoard6 = Board(rows: [
    Row(cells: [Cell(value: 1, marked: true), Cell(value: 2, marked: true)]),
    Row(cells: [Cell(value: 3, marked: true), Cell(value: 4, marked: true)]),
  ])
  if board6 != expectedBoard6 { fatalError() }

  print("\(#function) passed")
}