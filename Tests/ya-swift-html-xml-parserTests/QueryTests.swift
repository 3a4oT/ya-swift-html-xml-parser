import Testing

@testable import ya_swift_html_xml_parser

@Suite("Querying (XPath & CSS)")
struct QueryTests {
    @Test("XPath queries")
    func xPathQueries() async throws {
        let html = """
        <html>
          <body>
            <p>Some text and <a href="/page1.html">a link</a>.</p>
            <div class="content">
              <a href="https://www.apple.com">Apple</a>
              <a href="https://www.swift.org">Swift.org</a>
            </div>
            <div id="footer">
                <p>Footer text</p>
            </div>
          </body>
        </html>
        """
        let doc = try parseHTML(string: html)

        let allLinks = try doc.xpath("//a")
        #expect(allLinks.count == 3)

        let hrefs = allLinks.compactMap { $0.getAttribute("href") }
        #expect(
            hrefs.sorted() == ["/page1.html", "https://www.apple.com", "https://www.swift.org"].sorted())

        let contentLinks = try doc.xpath("//div[@class='content']/a")
        #expect(contentLinks.count == 2)
        #expect(contentLinks.first?.text == "Apple")

        let noResults = try doc.xpath("//div[@id='non-existent']")
        #expect(noResults.isEmpty)

        #expect(throws: XMLError.self) {
            _ = try doc.xpath("//div[@class='content]")
        }
    }

    @Test("CSS Selectors")
    func cSSSelectors() throws {
        let html = """
        <html>
          <body>
            <div id="main">
                <p class="intro active">Intro paragraph.</p>
                <p>Another paragraph.</p>
            </div>
            <div class="sidebar">
                <a href="/one">Link 1</a>
                <a class="external" href="/two">Link 2</a>
            </div>
          </body>
        </html>
        """
        let doc = try parseHTML(string: html)

        let paragraphs = try doc.select("p")
        #expect(paragraphs.count == 2)
        #expect(paragraphs.first?.text == "Intro paragraph.")

        let mainDiv = try doc.select("#main")
        #expect(mainDiv.count == 1)

        let intro = try doc.select(".intro")
        #expect(intro.count == 1)
        #expect(intro.first?.name == "p")

        let sidebarLinks = try doc.select(".sidebar a")
        #expect(sidebarLinks.count == 2)
        #expect(sidebarLinks.last?.getAttribute("class") == "external")

        let activeIntro = try doc.select("p.intro.active")
        #expect(activeIntro.count == 1)

        let mainParagraphs = try mainDiv.select("p")
        #expect(mainParagraphs.count == 2)

        let nonExistent = try doc.select(".non-existent")
        #expect(nonExistent.isEmpty)
    }
}
