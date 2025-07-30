import Testing
@testable import YaSwiftXML

@Suite("Concurrency Tests")
struct ConcurrencyTests {
    
    @Test("Concurrent XML parsing with extraction")
    func concurrentXMLParsing() async throws {
        let service = XMLParsingService()
        
        let xml1 = """
        <doc1>
            <title>First Document</title>
            <content>Content 1</content>
        </doc1>
        """
        
        let xml2 = """
        <doc2>
            <title>Second Document</title>
            <content>Content 2</content>
        </doc2>
        """
        
        // Parse and extract data concurrently
        async let rootName1 = service.parseXMLAndExtract(string: xml1) { doc in
            doc.rootElement?.name ?? ""
        }
        async let rootName2 = service.parseXMLAndExtract(string: xml2) { doc in
            doc.rootElement?.name ?? ""
        }
        
        let (name1, name2) = try await (rootName1, rootName2)
        
        // Verify results
        #expect(name1 == "doc1")
        #expect(name2 == "doc2")
    }
    
    @Test("Parse and extract pattern")
    func parseAndExtract() async throws {
        let service = XMLParsingService()
        
        let xml = """
        <books>
            <book>
                <title>Book 1</title>
                <author>Author 1</author>
            </book>
            <book>
                <title>Book 2</title>
                <author>Author 2</author>
            </book>
        </books>
        """
        
        // Extract titles in a thread-safe way
        let titles = try await service.parseXMLAndExtract(string: xml) { doc in
            var titles: [String] = []
            
            doc.rootElement?.forEachChild { book in
                if book.name == "book" {
                    book.forEachChild { child in
                        if child.name == "title", let content = child.content {
                            titles.append(content)
                        }
                    }
                }
            }
            
            return titles
        }
        
        #expect(titles == ["Book 1", "Book 2"])
    }
    
    @Test("Concurrent HTML parsing with extraction")
    func concurrentHTMLParsing() async throws {
        let service = XMLParsingService()
        
        let html1 = "<html><body><h1>Page 1</h1></body></html>"
        let html2 = "<html><body><h1>Page 2</h1></body></html>"
        
        // Parse and extract H1 content concurrently
        async let h1Content1 = service.parseHTMLAndExtract(string: html1) { doc in
            var h1Content: String?
            doc.rootElement?.forEachChild { child in
                if child.name == "body" {
                    child.forEachChild { bodyChild in
                        if bodyChild.name == "h1" {
                            h1Content = bodyChild.content
                        }
                    }
                }
            }
            return h1Content
        }
        
        async let h1Content2 = service.parseHTMLAndExtract(string: html2) { doc in
            var h1Content: String?
            doc.rootElement?.forEachChild { child in
                if child.name == "body" {
                    child.forEachChild { bodyChild in
                        if bodyChild.name == "h1" {
                            h1Content = bodyChild.content
                        }
                    }
                }
            }
            return h1Content
        }
        
        let (content1, content2) = try await (h1Content1, h1Content2)
        
        #expect(content1 == "Page 1")
        #expect(content2 == "Page 2")
    }
    
    @Test("Sequential parsing for non-Sendable documents")
    func sequentialParsing() async throws {
        let service = XMLParsingService()
        
        // When you need the actual XMLDocument, process it within the actor
        let xml = "<root><item>Test</item></root>"
        
        // Parse and extract all data in one atomic operation
        let (rootName, foundItem) = try await service.parseXMLAndExtract(string: xml) { doc in
            let rootName = doc.rootElement?.name
            var foundItem = false
            
            doc.rootElement?.forEachChild { child in
                if child.name == "item" && child.content == "Test" {
                    foundItem = true
                }
            }
            
            return (rootName, foundItem)
        }
        
        #expect(rootName == "root")
        #expect(foundItem)
    }
} 