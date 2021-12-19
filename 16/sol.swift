#!/usr/bin/env swift
import Foundation

protocol Packet {
  var version: UInt8 { get }
  var value: UInt64 { get }
  func versionSum() -> UInt64
}

struct LiteralPacket: Packet {
  let version: UInt8
  let value: UInt64

  func versionSum() -> UInt64 {
    return UInt64(version)
  }
}

struct OperatorPacket: Packet {
  enum LengthType: Equatable {
    case totalLength(Int)
    case numSubPackets(Int)
  }
  let version: UInt8
  let type: UInt8
  let subpackets: [Packet]
  
  func versionSum() -> UInt64 {
    return subpackets.reduce(UInt64(0), { $0 + $1.versionSum()}) + UInt64(version)
  }

  var value: UInt64 {
    switch type {
    case 0: return subpackets.reduce(UInt64(0), { $0 + $1.value })
    case 1: return subpackets.reduce(UInt64(1), { $0 * $1.value })
    case 2: return subpackets.min { $0.value < $1.value }!.value
    case 3: return subpackets.max { $0.value < $1.value }!.value
    case 5: return subpackets[0].value > subpackets[1].value ? 1 : 0
    case 6: return subpackets[0].value < subpackets[1].value ? 1 : 0
    case 7: return subpackets[0].value == subpackets[1].value ? 1 : 0
    default: return 0
    }
  }
}

func parsePacket(_ bitStream: BitStream) -> Packet {
  let version = UInt8(bitStream.consume(3))
  let packetTypeId = bitStream.consume(3)
  if packetTypeId == 4 {
    return parseLiteralPacket(version: version, bitStream: bitStream)
  } else {
    return parseOperatorPacket(version: version, packetTypeId: UInt8(packetTypeId), bitStream: bitStream)
  }
}

func parseOperatorPacket(version: UInt8, packetTypeId: UInt8, bitStream: BitStream) -> OperatorPacket {
  let lengthTypeId = bitStream.consume(1)
  switch lengthTypeId {
  case 0: 
    let subPacketBitLength = bitStream.consume(15)
    let subpackets = parseSubpackets(subPacketBitLength: subPacketBitLength, bitStream: bitStream)
    return OperatorPacket(version: version, type: packetTypeId, subpackets: subpackets)
  case 1:
    let numSubPackets = bitStream.consume(11)
    let subpackets = (0..<numSubPackets).map { _ in parsePacket(bitStream) }    
    return OperatorPacket(version: version, type: packetTypeId, subpackets: subpackets)
  default: fatalError("Wrong length type ID of \(lengthTypeId)")
  }
}

func parseSubpackets(subPacketBitLength: UInt64, bitStream: BitStream) -> [Packet] {
  var bitCount: UInt64 = 0
  var subpackets: [Packet] = []
  while bitCount < subPacketBitLength {
    let startConsumedBitCount = bitStream.totalConsumedBitCount
    subpackets.append(parsePacket(bitStream))
    let endConsumedBitCount = bitStream.totalConsumedBitCount
    bitCount += endConsumedBitCount - startConsumedBitCount
  }
  return subpackets
}

func parseLiteralPacket(version: UInt8, bitStream: BitStream) -> LiteralPacket {
  let literalValue = parseLiteralValue(bitStream)
  return LiteralPacket(version: version, value: literalValue)
}

func parseLiteralValue(_ bitStream: BitStream) -> UInt64 {
  var nibbles: [UInt8] = []
  while true {
    let value = bitStream.consume(5)
    nibbles.append(UInt8(value & 0b1111))
    if (value >> 4) == 0 { break }
  }

  return stitchNibbles(nibbles)
}

func stitchNibbles(_ nibbles: [UInt8]) -> UInt64 {
  let mask = createMask(4)
  return nibbles.enumerated().reduce(UInt64(0), { acc, args in 
    let shift = (nibbles.count - 1 - args.offset) * 4
    return acc | ((UInt64(args.element & mask) << shift)) 
  }) 
}

extension String {
  func components(withMaxLength length: Int) -> [String] {
    return stride(from: 0, to: self.count, by: length).map {
      let start = self.index(self.startIndex, offsetBy: $0)
      let end = self.index(start, offsetBy: length, limitedBy: self.endIndex) ?? self.endIndex
      return String(self[start..<end])
    }
  }
}

class ConsumableByte {
  var remainingBits: UInt8 = 8
  var value: UInt8
  init(value: UInt8) {
    self.value = value
  }

  func pop(_ totalBits: UInt8) -> UInt8 {
    assert(totalBits <= remainingBits)
    let shift = remainingBits - totalBits
    let mask = createMask(totalBits) << shift
    let retVal = (value & mask) >> shift
    remainingBits -= totalBits
    value = value & (~mask)
    return retVal
  }
}

class BitStream {
  private let bytes: [ConsumableByte]
  private var byteIndex: Int = 0
  var totalConsumedBitCount: UInt64 = 0

  convenience init (filename: String) {
    let path = FileManager.default.currentDirectoryPath.appending("/\(filename)")
    let string = try! String(contentsOfFile: path, encoding: String.Encoding.utf8)
    self.init(input: string)
  }

  init (input: String) {
    let input = (input.count % 2 == 0) ? input : (input + "0")
    self.bytes = input.components(withMaxLength: 2).map { ConsumableByte(value: UInt8($0, radix: 16)!) }
  }

  func consume(_ totalBits: UInt8) -> UInt64 {
    assert(totalBits <= 64)

    var bitsToConsume = totalBits
    var retVal = UInt64(0)
    while (bitsToConsume > 0) {
      let byte = bytes[byteIndex]
      let bits = min(bitsToConsume, byte.remainingBits)
      let value = UInt64(byte.pop(bits))
      retVal = retVal | UInt64(value << (bitsToConsume - bits))
      bitsToConsume -= bits
      totalConsumedBitCount += UInt64(bits)
      if byte.remainingBits == 0 {
        byteIndex += 1
      }
    }
    return retVal
  }
}

func createMask(_ bits: UInt8) -> UInt8 {
  return (0..<bits).reduce(0, { return $0 | (1 << $1) })
}

if CommandLine.arguments.count > 1, CommandLine.arguments[1] == "--test" {
  runTests()
} else {
  let bitStream = BitStream(filename: "input.txt")
  let packet = parsePacket(bitStream)
  print("Version sum: \(packet.versionSum())")
  print("Value: \(packet.value)")
}

/* TESTS */

func runTests() {
  testNibbleStitch()
  testLiteralPacket()
  testOperatorPacket()
  testOperatorPacket2()
  testNesting()
  testVersionSum()
  testBitStream()
  testConsumeBitsFromByte()
  testValues()
}

func testNibbleStitch() {
  assert(stitchNibbles([0b0111, 0b1110, 0b0101]) == 2021)
}

func testLiteralPacket() {
  let packet = parsePacket(BitStream(input: "D2FE28"))
  assert(packet is LiteralPacket)
  assert((packet as! LiteralPacket).value == 2021)
  assert(packet.version == 6)
}

func testOperatorPacket() {
  let packet = parsePacket(BitStream(input: "38006F45291200")) as! OperatorPacket
  assert(packet.subpackets.count == 2)
  assert((packet.subpackets[0] as! LiteralPacket).value == 10)
  assert((packet.subpackets[1] as! LiteralPacket).value == 20)
  assert(packet.version == 1)
  assert(packet.type == 6)
}

func testOperatorPacket2() {
  let packet = parsePacket(BitStream(input: "EE00D40C823060")) as! OperatorPacket
  assert(packet.subpackets.count == 3)
  assert((packet.subpackets[0] as! LiteralPacket).value == 1)
  assert((packet.subpackets[1] as! LiteralPacket).value == 2)
  assert((packet.subpackets[2] as! LiteralPacket).value == 3)
  assert(packet.version == 7)
  assert(packet.type == 3)
}

func testNesting() {
  let packet1 = parsePacket(BitStream(input: "A0016C880162017C3686B18A3D4780")) as! OperatorPacket
  assert(packet1.subpackets.count == 1)
  let packet2 = packet1.subpackets[0] as! OperatorPacket
  assert(packet2.subpackets.count == 1)
  let packet3 = packet2.subpackets[0] as! OperatorPacket
  assert(packet3.subpackets.count == 5)
}

func testVersionSum() {
  assert(parsePacket(BitStream(input: "8A004A801A8002F478")).versionSum() == 16)
  assert(parsePacket(BitStream(input: "620080001611562C8802118E34")).versionSum() == 12)
  assert(parsePacket(BitStream(input: "C0015000016115A2E0802F182340")).versionSum() == 23)
  assert(parsePacket(BitStream(input: "A0016C880162017C3686B18A3D4780")).versionSum() == 31)
}

func testConsumeBitsFromByte() {
  let byte = ConsumableByte(value: 0b10011010)
  assert(byte.pop(3) == 0b100)
  assert(byte.remainingBits == 5)
  assert(byte.pop(3) == 0b110)
  assert(byte.remainingBits == 2)
  assert(byte.pop(2) == 0b10)
  assert(byte.remainingBits == 0)
}

func testBitStream() {
  let bitStream = BitStream(input: "D2FE28")
  assert(bitStream.consume(3) == 0b110)
  assert(bitStream.consume(5) == 0b10010)
  assert(bitStream.consume(9) == 0b111111100)
  // assert(bitStream.consume(64) == 0b0101000)
}

func testValues() {
  assert(parsePacket(BitStream(input: "C200B40A82")).value == 3)
  assert(parsePacket(BitStream(input: "04005AC33890")).value == 54)
  assert(parsePacket(BitStream(input: "880086C3E88112")).value == 7)
  assert(parsePacket(BitStream(input: "CE00C43D881120")).value == 9)
  assert(parsePacket(BitStream(input: "D8005AC2A8F0")).value == 1)
  assert(parsePacket(BitStream(input: "F600BC2D8F")).value == 0)
  assert(parsePacket(BitStream(input: "9C005AC2F8F0")).value == 0)
  assert(parsePacket(BitStream(input: "9C0141080250320F1802104A08")).value == 1)
}