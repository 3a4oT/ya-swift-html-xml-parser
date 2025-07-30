import CLibXML2

/// Event types emitted by the stream parser
public enum StreamEvent: Sendable {
    case startDocument
    case endDocument
    case startElement(name: String, attributes: [(String, String)])
    case endElement(name: String)
    case characters(String)
    case comment(String)
    case cdata(String)
    case processingInstruction(target: String, data: String?)
    case error(String)
}

/// Protocol for handling stream events
public protocol StreamEventHandler: AnyObject {
    /// Handle a stream event
    func handleEvent(_ event: StreamEvent)
}

/// A stream-based parser that processes documents incrementally
/// - Warning: This class is NOT thread-safe. libxml2 uses global state and callbacks.
public final class StreamParser {
    private var context: xmlParserCtxtPtr?
    private let handler: any StreamEventHandler
    private let options: StreamParserOptions
    
    public struct StreamParserOptions: Sendable {
        public var chunkSize: Int
        public var isHTML: Bool
        
        public init(
            chunkSize: Int = 4096,
            isHTML: Bool = false
        ) {
            self.chunkSize = chunkSize
            self.isHTML = isHTML
        }
    }
    
    public init(handler: any StreamEventHandler, options: StreamParserOptions = StreamParserOptions()) {
        self.handler = handler
        self.options = options
    }
    
    deinit {
        if let ctx = context {
            if options.isHTML {
                htmlFreeParserCtxt(ctx)
            } else {
                xmlFreeParserCtxt(ctx)
            }
        }
    }
    
    /// Parse data from a byte buffer
    /// - Note: This method is NOT thread-safe. libxml2 uses global state during parsing.
    public func parse(bytes: UnsafeBufferPointer<UInt8>) throws {
        try initializeContext()
        try parseChunk(bytes)
        try finalize()
    }
    
    /// Parse data from a file
    /// - Note: This method is NOT thread-safe. libxml2 uses global state during parsing.
    public func parseFile(at path: String) throws {
        try initializeContext()
        
        // Use C file operations instead of FileHandle
        guard let file = fopen(path, "rb") else {
            throw ParsingError.streamError("Failed to open file")
        }
        defer { fclose(file) }
        
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: options.chunkSize)
        defer { buffer.deallocate() }
        
        while true {
            let bytesRead = fread(buffer, 1, options.chunkSize, file)
            guard bytesRead > 0 else { break }
            
            let chunk = UnsafeBufferPointer(start: buffer, count: bytesRead)
            try parseChunk(chunk)
        }
        
        try finalize()
    }
    
    private func initializeContext() throws {
        // Set up SAX handlers
        var saxHandler = xmlSAXHandler()
        
        saxHandler.startDocument = { userData in
            let parser = Unmanaged<StreamParser>.fromOpaque(userData!).takeUnretainedValue()
            parser.handler.handleEvent(.startDocument)
        }
        
        saxHandler.endDocument = { userData in
            let parser = Unmanaged<StreamParser>.fromOpaque(userData!).takeUnretainedValue()
            parser.handler.handleEvent(.endDocument)
        }
        
        saxHandler.startElement = { userData, name, attributes in
            let parser = Unmanaged<StreamParser>.fromOpaque(userData!).takeUnretainedValue()
            let elementName = String(cString: name!)
            var attrs: [(String, String)] = []
            
            if let attributesPtr = attributes {
                var i = 0
                while let attrName = attributesPtr[i], let attrValue = attributesPtr[i + 1] {
                    attrs.append((String(cString: attrName), String(cString: attrValue)))
                    i += 2
                }
            }
            
            parser.handler.handleEvent(.startElement(name: elementName, attributes: attrs))
        }
        
        saxHandler.endElement = { userData, name in
            let parser = Unmanaged<StreamParser>.fromOpaque(userData!).takeUnretainedValue()
            let elementName = String(cString: name!)
            parser.handler.handleEvent(.endElement(name: elementName))
        }
        
        saxHandler.characters = { userData, ch, len in
            let parser = Unmanaged<StreamParser>.fromOpaque(userData!).takeUnretainedValue()
            let buffer = UnsafeBufferPointer(start: ch!, count: Int(len))
            let string = String(decoding: buffer, as: UTF8.self)
            parser.handler.handleEvent(.characters(string))
        }
        
        // Create parser context
        let userData = Unmanaged.passUnretained(self).toOpaque()
        
        if options.isHTML {
            context = htmlCreatePushParserCtxt(&saxHandler, userData, nil, 0, nil, XML_CHAR_ENCODING_UTF8)
        } else {
            context = xmlCreatePushParserCtxt(&saxHandler, userData, nil, 0, nil)
        }
        
        guard context != nil else {
            throw ParsingError.streamError("Failed to create parser context")
        }
    }
    
    private func parseChunk(_ bytes: UnsafeBufferPointer<UInt8>) throws {
        guard let ctx = context else {
            throw ParsingError.streamError("Parser context not initialized")
        }
        
        try bytes.withMemoryRebound(to: CChar.self) { charBuffer in
            let result: Int32
            
            if options.isHTML {
                result = htmlParseChunk(ctx, charBuffer.baseAddress, Int32(charBuffer.count), 0)
            } else {
                result = xmlParseChunk(ctx, charBuffer.baseAddress, Int32(charBuffer.count), 0)
            }
            
            if result != 0 {
                throw ParsingError.streamError("Failed to parse chunk")
            }
        }
    }
    
    private func finalize() throws {
        guard let ctx = context else { return }
        
        let result: Int32
        if options.isHTML {
            result = htmlParseChunk(ctx, nil, 0, 1)
        } else {
            result = xmlParseChunk(ctx, nil, 0, 1)
        }
        
        if result != 0 {
            throw ParsingError.streamError("Failed to finalize parsing")
        }
    }
}

/// A simple event handler that collects events
/// - Warning: This class is NOT thread-safe. Use appropriate synchronization if accessed from multiple threads.
public final class CollectingEventHandler: StreamEventHandler {
    private var events: [StreamEvent] = []
    
    public init() {}
    
    public func handleEvent(_ event: StreamEvent) {
        events.append(event)
    }
    
    public var collectedEvents: [StreamEvent] {
        return events
    }
} 