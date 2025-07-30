import Testing

@testable import ya_swift_html_xml_parser

@Suite("Real-World HTML Parsing")
struct HTMLParsingTests {

  private static let sampleHTML = #"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>Test Page</title>
        <link rel="stylesheet" href="/styles.css">
    </head>
    <body>
        <header>
            <h1>Main Title</h1>
            <nav>
                <ul>
                    <li><a href="/">Home</a></li>
                    <li><a href="/about" class="nav-link active">About</a></li>
                </ul>
            </nav>
        </header>

        <main id="content">
            <!-- This is the main content -->
            <p class="intro first">This is the intro paragraph with <strong>bold</strong> text.</p>
            <p>This is the second paragraph.</p>
            <img src="/image.png" alt="An image">
        </main>
        
        <footer>
            <script src="/script.js"></script>
        </footer>
    </body>
    </html>
    """#

  @Test("Test basic document structure")
  func testBasicDocumentParsing() throws {
    let doc = try parseHTML(string: Self.sampleHTML)

    let htmlNode = try #require(doc.rootElement)
    #expect(htmlNode.name == "html")

    let headNode = try #require(try htmlNode.find(where: { $0.name == "head" }).first)
    let titleNode = try #require(try headNode.find(where: { $0.name == "title" }).first)
    #expect(titleNode.text == "Test Page")

    let bodyNode = try #require(try htmlNode.find(where: { $0.name == "body" }).first)
    #expect(bodyNode.children.filter({ $0.type == .element }).count == 3)
  }

  @Test("Test CSS selector queries")
  func testCSSelectorQueries() throws {
    let doc = try parseHTML(string: Self.sampleHTML)

    let mainContent = try doc.select("#content")
    #expect(mainContent.count == 1)
    #expect(mainContent.first?.name == "main")

    let activeLinks = try doc.select(".active")
    #expect(activeLinks.count == 1)
    #expect(activeLinks.first?.text == "About")

    let navLinks = try doc.select("nav a")
    #expect(navLinks.count == 2)

    let introParagraph = try doc.select("p.intro.first")
    #expect(introParagraph.count == 1)
  }

  @Test("Test recursive text extraction")
  func testRecursiveTextExtraction() throws {
    let doc = try parseHTML(string: Self.sampleHTML)
    let intro = try #require(doc.select(".intro").first)

    let expectedText = "This is the intro paragraph with bold text."
    let actualText = intro.text

    let normalizedActual = actualText.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    #expect(normalizedActual == expectedText)
  }

  @Test("Test URL and attribute extraction")
  func testURLAndAttributeExtraction() throws {
    let doc = try parseHTML(string: Self.sampleHTML)

    let allUrls = try doc.urls()
    #expect(allUrls.count == 5)
    #expect(allUrls.contains("/styles.css"))
    #expect(allUrls.contains("/image.png"))
    #expect(allUrls.contains("/script.js"))

    let nav = try #require(doc.select("nav").first)
    let navUrls = try nav.urls(from: .a)
    #expect(navUrls.count == 2)
    #expect(navUrls == ["/", "/about"])

    let image = try #require(doc.select("img").first)
    #expect(image.getAttribute("alt") == "An image")
  }

  @Test("Test find() throws on exceeding max depth")
  func testFindThrowsOnExceedingMaxDepth() throws {
    let doc = try parseHTML(string: Self.sampleHTML)
    // Start the search from the `<main>` element to isolate the test.
    let mainContent = try #require(doc.select("#content").first)

    // Inside `<main>`, the structure is:
    // main (depth 0) -> p (depth 1) -> strong (depth 2) -> text (depth 3)

    // A limit of 1 should fail, as it cannot reach the `<strong>` tag.
    #expect(throws: XMLError.depthLimitExceeded(limit: 1)) {
      _ = try mainContent.find(maxDepth: 1, where: { $0.name == "strong" })
    }

    // A limit of 2 should also fail. It finds the `<strong>` tag, but then
    // throws when it attempts to process its child text node at depth 3.
    #expect(throws: XMLError.depthLimitExceeded(limit: 2)) {
      _ = try mainContent.find(maxDepth: 2, where: { $0.name == "strong" })
    }

    // A limit of 3 allows the traversal to visit the text node at depth 3,
    // so the operation completes without error.
    let strongTag = try mainContent.find(maxDepth: 3, where: { $0.name == "strong" })
    #expect(strongTag.count == 1)
  }
}

extension XMLError: Equatable {
  public static func == (lhs: XMLError, rhs: XMLError) -> Bool {
    switch (lhs, rhs) {
    case (.depthLimitExceeded(let l), .depthLimitExceeded(let r)):
      return l == r
    case (.css(let l), .css(let r)):
      return l == r
    default:
      return false
    }
  }
}
