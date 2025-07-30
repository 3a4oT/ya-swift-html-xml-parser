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

@Suite("Basic XML Parsing")
struct BasicParsingTests {

  private let blogXML = """
    <feed>
        <title>My Awesome Blog</title>
        <entry>
            <title>A Great Post</title>
            <link href="/posts/1" type="text/html"/>
            <summary>This is a summary.</summary>
            <category term="swift"/>
        </entry>
        <entry>
            <title>Another Fine Post</title>
            <link href="/posts/2" type="text/html"/>
            <summary>More great content.</summary>
            <category term="parsing"/>
            <category term="swift"/>
        </entry>
    </feed>
    """

  @Test("Test Document Parsing and Root Element Access")
  func testDocumentParsing() throws {
    let doc = try parseXML(string: blogXML)

    let root = try #require(doc.rootElement)
    #expect(root.name == "feed")

    let title = try #require(try root.find(where: { $0.name == "title" }).first)
    #expect(title.text == "My Awesome Blog")
  }

  @Test("Test find() to locate specific nodes")
  func testFindNodes() throws {
    let doc = try parseXML(string: blogXML)
    let root = try #require(doc.rootElement)

    let allEntries = try root.find(where: { $0.name == "entry" })
    #expect(allEntries.count == 2)

    let swiftCategoryItems = try root.find(where: {
      $0.name == "category" && $0.getAttribute("term") == "swift"
    })
    #expect(swiftCategoryItems.count == 2)

    let parsingCategoryItem = try root.find(where: {
      $0.name == "category" && $0.getAttribute("term") == "parsing"
    })
    #expect(parsingCategoryItem.count == 1)
  }

  @Test("Test Attribute and Text Access")
  func testAttributeAndTextAccess() throws {
    let doc = try parseXML(string: blogXML)
    let root = try #require(doc.rootElement)

    let firstEntry = try #require(try root.find(where: { $0.name == "entry" }).first)
    #expect(firstEntry.name == "entry")

    let link = try #require(try firstEntry.find(where: { $0.name == "link" }).first)
    #expect(link.getAttribute("href") == "/posts/1")
    #expect(link.getAttribute("type") == "text/html")
    #expect(link.getAttribute("rel") == nil)

    let summary = try #require(try firstEntry.find(where: { $0.name == "summary" }).first)
    #expect(summary.text == "This is a summary.")
  }

  @Test("Test Strict Parsing Fails on Malformed XML")
  func testStrictParsingFailure() throws {
    let malformedXML = "<feed><title>Unclosed"

    #expect(throws: XMLError.self) {
      // The global parseXML function uses .strict options by default
      _ = try parseXML(string: malformedXML)
    }
  }

  @Test("Test Default Lenient Parsing Recovers from Errors")
  func testDefaultParsingRecovery() throws {
    // This XML has a mismatched closing tag, which is a recoverable error.
    let recoverableXML = "<feed><title>Title</wrong_tag></feed>"

    // Use the top-level function with lenient options to recover from the error.
    let doc = try parseXML(string: recoverableXML, options: .lenientXML)

    // Even with the error, the document should be parsed and accessible.
    let root = try #require(doc.rootElement)
    #expect(root.name == "feed")
    let title = try #require(try root.find(where: { $0.name == "title" }).first)
    #expect(title.text == "Title")
  }

  @Test("Parse simple HTML")
  func parseSimpleHTML() throws {
    let html = """
      <html>
          <body>
              <h1>Title</h1>
              <p class="content">Paragraph</p>
          </body>
      </html>
      """

    let doc = try parseHTML(string: html)
    #expect(doc.rootElement != nil)

    let root = try #require(doc.rootElement)
    #expect(root.name == "html")

    let body = try #require(try root.find(where: { $0.name == "body" }).first)

    let h1 = try #require(try body.find(where: { $0.name == "h1" }).first)
    #expect(h1.text == "Title")

    let p = try #require(try body.find(where: { $0.name == "p" }).first)
    #expect(p.text == "Paragraph")
    #expect(p.getAttribute("class") == "content")
  }
}
