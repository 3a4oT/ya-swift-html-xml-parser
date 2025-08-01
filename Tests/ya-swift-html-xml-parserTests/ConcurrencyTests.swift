import Testing

@testable import ya_swift_html_xml_parser

@Suite("Concurrency Tests")
struct ConcurrencyTests {
    // A collection of XML documents to be parsed concurrently.
    // This simulates a real-world scenario like fetching multiple RSS feeds.
    private let xmlBatch = [
        "<doc><title>Document 1</title></doc>",
        "<doc><title>Document 2</title><item>An item</item></doc>",
        "<doc><title>Document 3</title></doc>"
    ]

    /// This test demonstrates the primary use case for the `ParsingService`:
    /// processing a batch of documents concurrently and safely extracting data.
    @Test("Test Concurrent Batch Processing with TaskGroup")
    func concurrentBatchProcessing() async throws {
        let service = ParsingService()

        // Use a ThrowingTaskGroup to manage concurrent parsing operations that can throw.
        let titles = try await withThrowingTaskGroup(of: String.self, returning: [String].self) {
            group in
            for xmlString in self.xmlBatch {
                group.addTask {
                    // The `parseXMLAndExtract` method ensures that document access
                    // and data extraction are performed safely within the actor.
                    return try await service.parseXMLAndExtract(string: xmlString) { doc in
                        // Use the high-level query API for cleaner extraction.
                        try doc.select("title").first?.text ?? "Untitled"
                    }
                }
            }

            var collectedTitles: [String] = []
            for try await title in group {
                collectedTitles.append(title)
            }
            return collectedTitles
        }

        // Verify the results. The order is not guaranteed due to concurrency,
        // so we sort both arrays to ensure the comparison is stable.
        let expectedTitles = ["Document 1", "Document 2", "Document 3"]
        #expect(titles.sorted() == expectedTitles.sorted())
    }

    /// This test focuses on the `parseHTMLAndExtract` variant and ensures
    /// that HTML documents can also be processed concurrently.
    @Test("Test Concurrent HTML Parsing")
    func concurrentHTMLParsing() async throws {
        let service = ParsingService()

        let html1 = "<html><body><h1>Page 1</h1></body></html>"
        let html2 = "<html><body><h2>Page 2</h2></body></html>"

        async let heading1 = service.parseHTMLAndExtract(string: html1) { doc in
            try doc.select("h1").first?.text
        }

        async let heading2 = service.parseHTMLAndExtract(string: html2) { doc in
            try doc.select("h2").first?.text
        }

        let (h1, h2) = try await (heading1, heading2)

        #expect(h1 == "Page 1")
        #expect(h2 == "Page 2")
    }
}
