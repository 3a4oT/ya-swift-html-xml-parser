import Testing

@testable import ya_swift_html_xml_parser

#if canImport(Darwin)
  import Darwin.C
#elseif canImport(Glibc)
  import Glibc
#elseif canImport(Musl)
  import Musl
#elseif canImport(Android)
  import Android
#elseif os(Windows)
  import ucrt
  import CRT
  import WinSDK
#elseif os(WASI)
  import WASILibc
#endif

@Suite("Stream Parser Tests")
struct StreamParserTests {

  @Test("Stream parsing")
  func testBasicStreamParsing() throws {
    let xml = #"<root a="1" b="2"><item>1</item><item>2</item></root>"#

    let handler = CollectingEventHandler()
    let parser = try StreamParser(handler: handler)

    var mutableXml = xml
    try mutableXml.withUTF8 { buffer in
      try parser.parse(bytes: UnsafeBufferPointer(start: buffer.baseAddress, count: buffer.count))
    }

    let events = handler.collectedEvents
    #expect(events.count > 0)

    var hasStartDoc = false
    var hasEndDoc = false
    var rootElementCount = 0
    var attributeCount = 0

    for event in events {
      switch event {
      case .startDocument:
        hasStartDoc = true
      case .endDocument:
        hasEndDoc = true
      case .startElement(let name, let attributes):
        if name == "root" {
          rootElementCount += 1
          for (attrName, attrValue) in attributes {
            if attrName == "a" && attrValue == "1" {
              attributeCount += 1
            }
            if attrName == "b" && attrValue == "2" {
              attributeCount += 1
            }
          }
        }
      default:
        break
      }
    }

    #expect(hasStartDoc)
    #expect(hasEndDoc)
    #expect(rootElementCount == 1)
    #expect(attributeCount == 2)
  }

  @Test("Stream parsing with custom chunk size from file")
  func testStreamParserWithCustomChunkSize() throws {
    let xmlContent = "<data><item>First</item><item>Second</item></data>"
    let testFileName = "test_chunking.xml"

    let file = fopen(testFileName, "w")
    #expect(file != nil, "Failed to create temporary file for testing.")
    if let file = file {
      _ = xmlContent.withCString { fputs($0, file) }
      fclose(file)
    }
    defer {
      remove(testFileName)
    }

    let handler = CollectingEventHandler()
    let options = StreamParserOptions(chunkSize: .bytes(10))
    let parser = try StreamParser(handler: handler, options: options)

    try parser.parseFile(at: testFileName)

    let events = handler.collectedEvents
    #expect(events.count > 0)

    let characterEvents = events.compactMap { event -> String? in
      if case .characters(let string) = event {
        return string
      }
      return nil
    }

    #expect(
      characterEvents == ["First", "Second"],
      "The parsed character data did not match the expected content.")
  }

  @Test("Stream parser throws on invalid chunk size")
  func testThrowsOnInvalidChunkSize() throws {
    let handler = CollectingEventHandler()
    let largeChunkSize = ChunkSize.bytes(Int(Int32.max) + 1)
    let options = StreamParserOptions(chunkSize: largeChunkSize)

    #expect(throws: XMLError.self) {
      _ = try StreamParser(handler: handler, options: options)
    }
  }
}
