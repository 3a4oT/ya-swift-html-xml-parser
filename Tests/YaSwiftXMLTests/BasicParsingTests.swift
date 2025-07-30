import Testing
@testable import YaSwiftXML

@Suite("Basic XML/HTML Parsing")
struct BasicParsingTests {
    
    @Test("Parse simple XML")
    func parseSimpleXML() throws {
        let xml = """
        <root>
            <child id="1">Hello</child>
            <child id="2">World</child>
        </root>
        """
        
        let doc = try parseXML(string: xml)
        #expect(doc.rootElement != nil)
        
        let root = doc.rootElement!
        #expect(root.name == "root")
        
        var childCount = 0
        root.forEachChild { child in
            if child.type == .element {
                childCount += 1
                #expect(child.name == "child")
                #expect(child.content == "Hello" || child.content == "World")
                #expect(child.getAttribute("id") == "1" || child.getAttribute("id") == "2")
            }
        }
        #expect(childCount == 2)
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
        
        let root = doc.rootElement!
        #expect(root.name == "html")
        
        // Find body
        var foundBody = false
        root.forEachChild { child in
            if child.name == "body" {
                foundBody = true
                
                // Check body's children
                child.forEachChild { bodyChild in
                    if bodyChild.name == "h1" {
                        #expect(bodyChild.content == "Title")
                    } else if bodyChild.name == "p" {
                        #expect(bodyChild.content == "Paragraph")
                        #expect(bodyChild.getAttribute("class") == "content")
                    }
                }
            }
        }
        #expect(foundBody)
    }
    
    @Test("Stream parsing")
    func streamParsing() throws {
        let xml = "<root><item>1</item><item>2</item></root>"
        
        let handler = CollectingEventHandler()
        let parser = StreamParser(handler: handler)
        
        let bytes = Array(xml.utf8)
        try bytes.withUnsafeBufferPointer { buffer in
            try parser.parse(bytes: buffer)
        }
        
        let events = handler.collectedEvents
        #expect(events.count > 0)
        
        // Check for expected events
        var hasStartDoc = false
        var hasEndDoc = false
        var rootElementCount = 0
        
        for event in events {
            switch event {
            case .startDocument:
                hasStartDoc = true
            case .endDocument:
                hasEndDoc = true
            case .startElement(let name, _):
                if name == "root" {
                    rootElementCount += 1
                }
            default:
                break
            }
        }
        
        #expect(hasStartDoc)
        #expect(hasEndDoc)
        #expect(rootElementCount == 1)
    }
} 