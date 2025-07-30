import CLibXML2

/// A thread-safe parsing service that serializes all parsing operations.
/// 
/// Since libxml2 uses global state during parsing, this actor ensures
/// that only one parsing operation happens at a time, making it safe
/// to use from multiple concurrent contexts.
///
/// Example usage:
/// ```swift
/// let service = XMLParsingService()
/// 
/// // Parse multiple documents concurrently
/// async let xml1 = service.parseXML(string: xmlString1)
/// async let xml2 = service.parseXML(string: xmlString2)
/// 
/// // The actor ensures these parse operations don't interfere
/// let (doc1, doc2) = try await (xml1, xml2)
/// 
/// // Important: XMLDocument is NOT Sendable, so process it 
/// // on the same task where it was created
/// ```
///
/// - Warning: While parsing is thread-safe through this actor,
///   the returned XMLDocument instances are NOT thread-safe.
///   Process them on the same task where they were created.
public actor XMLParsingService {
    private let memoryParser = MemoryParser()
    private let htmlParser = MemoryParser(options: .defaultHTML)
    
    public init() {}
    
    /// Parse XML from a string in a thread-safe manner
    public func parseXML(string: String) throws -> XMLDocument {
        try memoryParser.parse(string: string)
    }
    
    /// Parse HTML from a string in a thread-safe manner
    public func parseHTML(string: String) throws -> XMLDocument {
        try htmlParser.parse(string: string)
    }
    
    /// Parse XML from bytes in a thread-safe manner
    public func parseXML(bytes: UnsafeBufferPointer<UInt8>) throws -> XMLDocument {
        try memoryParser.parse(bytes: bytes)
    }
    
    /// Parse HTML from bytes in a thread-safe manner
    public func parseHTML(bytes: UnsafeBufferPointer<UInt8>) throws -> XMLDocument {
        try htmlParser.parse(bytes: bytes)
    }
    
    /// Parse XML from a file in a thread-safe manner
    public func parseXMLFile(at path: String) throws -> XMLDocument {
        try memoryParser.parseFile(at: path)
    }
    
    /// Parse HTML from a file in a thread-safe manner
    public func parseHTMLFile(at path: String) throws -> XMLDocument {
        try htmlParser.parseFile(at: path)
    }
    
    /// Parse and extract data in one atomic operation
    /// 
    /// This method is useful when you need to parse and immediately
    /// extract Sendable data from the document without keeping
    /// the non-Sendable XMLDocument around.
    ///
    /// Example:
    /// ```swift
    /// let titles = try await service.parseXMLAndExtract(string: xml) { doc in
    ///     var titles: [String] = []
    ///     doc.rootElement?.forEachChild { node in
    ///         if node.name == "title" {
    ///             titles.append(node.content ?? "")
    ///         }
    ///     }
    ///     return titles
    /// }
    /// ```
    public func parseXMLAndExtract<T: Sendable>(
        string: String,
        extract: (XMLDocument) throws -> T
    ) throws -> T {
        let doc = try parseXML(string: string)
        return try extract(doc)
    }
    
    /// Parse HTML and extract data in one atomic operation
    public func parseHTMLAndExtract<T: Sendable>(
        string: String,
        extract: (XMLDocument) throws -> T
    ) throws -> T {
        let doc = try parseHTML(string: string)
        return try extract(doc)
    }
} 