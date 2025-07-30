import CLibXML2

/// Options for memory-based parsing
public struct MemoryParserOptions: Sendable {
    public var options: Int32
    public var isHTML: Bool
    
    public init(
        options: Int32 = 0,
        isHTML: Bool = false
    ) {
        self.options = options
        self.isHTML = isHTML
    }
    
    public static let defaultXML = MemoryParserOptions(
        options: Int32(XML_PARSE_RECOVER.rawValue | XML_PARSE_NOERROR.rawValue | XML_PARSE_NOWARNING.rawValue)
    )
    
    public static let defaultHTML = MemoryParserOptions(
        options: Int32(HTML_PARSE_RECOVER.rawValue | HTML_PARSE_NOERROR.rawValue | HTML_PARSE_NOWARNING.rawValue),
        isHTML: true
    )
}

/// A memory-based parser that loads the entire document into memory
/// This parser is non-copyable to ensure single ownership of parsing resources
public struct MemoryParser: ~Copyable {
    private let options: MemoryParserOptions
    
    public init(options: MemoryParserOptions = .defaultXML) {
        self.options = options
    }
    
    /// Parse XML/HTML from a byte buffer
    /// - Note: This method is NOT thread-safe. libxml2 uses global state during parsing.
    public func parse(bytes: UnsafeBufferPointer<UInt8>) throws -> XMLDocument {
        return try bytes.withMemoryRebound(to: CChar.self) { charBuffer in
            try parseBuffer(charBuffer)
        }
    }
    
    /// Parse XML/HTML from a String
    /// - Note: This method is NOT thread-safe. libxml2 uses global state during parsing.
    public func parse(string: borrowing String) throws -> XMLDocument {
        return try string.withCString { cString in
            let length = string.utf8.count
            let buffer = UnsafeBufferPointer(start: cString, count: length)
            return try parseBuffer(buffer)
        }
    }
    
    /// Parse XML/HTML from a file
    /// - Note: This method is NOT thread-safe. libxml2 uses global state during parsing.
    public func parseFile(at path: String) throws -> XMLDocument {
        let docPtr: xmlDocPtr?
        
        if options.isHTML {
            docPtr = htmlReadFile(path, nil, options.options)
        } else {
            docPtr = xmlReadFile(path, nil, options.options)
        }
        
        guard let doc = docPtr else {
            throw ParsingError.parsingFailed(getLastError())
        }
        
        return XMLDocument(doc)
    }
    
    private func parseBuffer(_ buffer: UnsafeBufferPointer<CChar>) throws -> XMLDocument {
        let docPtr: xmlDocPtr?
        
        if options.isHTML {
            docPtr = htmlReadMemory(
                buffer.baseAddress,
                Int32(buffer.count),
                nil,
                nil,
                options.options
            )
        } else {
            docPtr = xmlReadMemory(
                buffer.baseAddress,
                Int32(buffer.count),
                nil,
                nil,
                options.options
            )
        }
        
        guard let doc = docPtr else {
            throw ParsingError.parsingFailed(getLastError())
        }
        
        return XMLDocument(doc)
    }
    
    private func getLastError() -> String {
        let error = xmlGetLastError()
        defer { xmlResetLastError() }
        
        guard let err = error else {
            return "Unknown parsing error"
        }
        
        return String(cString: err.pointee.message)
    }
}

public enum ParsingError: Error, Sendable {
    case encodingError
    case parsingFailed(String)
    case streamError(String)
}

/// Convenience functions for quick parsing
/// - Warning: These functions are NOT thread-safe due to libxml2's global state
public func parseXML(bytes: UnsafeBufferPointer<UInt8>) throws -> XMLDocument {
    let parser = MemoryParser(options: .defaultXML)
    return try parser.parse(bytes: bytes)
}

public func parseXML(string: borrowing String) throws -> XMLDocument {
    let parser = MemoryParser(options: .defaultXML)
    return try parser.parse(string: string)
}

public func parseHTML(bytes: UnsafeBufferPointer<UInt8>) throws -> XMLDocument {
    let parser = MemoryParser(options: .defaultHTML)
    return try parser.parse(bytes: bytes)
}

public func parseHTML(string: borrowing String) throws -> XMLDocument {
    let parser = MemoryParser(options: .defaultHTML)
    return try parser.parse(string: string)
} 