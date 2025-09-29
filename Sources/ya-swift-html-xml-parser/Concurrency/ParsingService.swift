import CLibXML2

/// A thread-safe parsing service that serializes all parsing operations.
///
/// `libxml2`, the underlying C library, uses global state during parsing, which makes it unsafe
/// to call from multiple threads simultaneously. This actor provides a safe serialization layer.
///
/// ## Real-World Use Case: Unblocking a UI Application
///
/// A common scenario is needing to parse multiple documents (e.g., from network requests)
/// in a background task without blocking the main thread of a UI application. The `ParsingService`
/// is ideal for this. You can create a `TaskGroup` to perform all parsing work concurrently
/// in the background. The actor guarantees that each parsing operation is handled atomically,
/// preventing race conditions.
///
/// ## Important Considerations
///
/// - **Result Order**: When using a `TaskGroup` for concurrent operations, the order in which
///   results are returned is not guaranteed.
///
/// - **`XMLDocument` is Not `Sendable`**: The `XMLDocument` instances created by the parser
///   are not thread-safe themselves. They must not be passed between different concurrent tasks.
///   The `parseXMLAndExtract` and `parseHTMLAndExtract` methods are the recommended way to
///   work around this limitation, as they ensure the document is processed and discarded
///   safely within the actor's context, returning only a `Sendable` result.
///
public actor ParsingService {
    private let memoryParser = MemoryParser()
    private let htmlParser = MemoryParser(options: .lenientHTML)

    public init() {}

    /// Parse XML from a string in a thread-safe manner
    public func parseXML(string: String) throws(XMLError) -> XMLDocument {
        try self.memoryParser.parse(string: string)
    }

    /// Parse HTML from a string in a thread-safe manner
    public func parseHTML(string: String) throws(XMLError) -> XMLDocument {
        try self.htmlParser.parse(string: string)
    }

    /// Parse XML from bytes in a thread-safe manner
    public func parseXML(bytes: UnsafeBufferPointer<UInt8>) throws(XMLError) -> XMLDocument {
        try self.memoryParser.parse(bytes: Span(_unsafeElements: bytes))
    }

    /// Parse HTML from bytes in a thread-safe manner
    public func parseHTML(bytes: UnsafeBufferPointer<UInt8>) throws(XMLError) -> XMLDocument {
        try self.htmlParser.parse(bytes: Span(_unsafeElements: bytes))
    }

    /// Parse XML from a file in a thread-safe manner
    public func parseXMLFile(at path: String) throws(XMLError) -> XMLDocument {
        try self.memoryParser.parseFile(at: path)
    }

    /// Parse HTML from a file in a thread-safe manner
    public func parseHTMLFile(at path: String) throws(XMLError) -> XMLDocument {
        try self.htmlParser.parseFile(at: path)
    }

    /// Parses an XML string and extracts a `Sendable` value in a thread-safe manner.
    ///
    /// This is the recommended method for concurrent parsing, as it encapsulates document access
    /// within the actor's serialization context, preventing data races.
    ///
    /// - Parameters:
    ///   - string: The XML string to parse.
    ///   - extract: A closure that takes the parsed `XMLDocument` and returns a `Sendable` value.
    /// - Returns: The value returned by the `extract` closure.
    /// - Throws: Rethrows any `XMLError` from parsing or any error thrown by the `extract` closure,
    ///   wrapping the latter in `XMLError.userTransformError`.
    public func parseXMLAndExtract<T: Sendable>(
        string: String,
        extract: (XMLDocument) throws -> T
    ) async throws(XMLError) -> T {
        do {
            let doc = try parseXML(string: string)
            return try extract(doc)
        } catch {
            throw XMLError.userTransformError(
                message: "The user-provided transform closure failed: \(error)")
        }
    }

    /// Parses an HTML string and extracts a `Sendable` value in a thread-safe manner.
    ///
    /// This is the recommended method for concurrent parsing, as it encapsulates document access
    /// within the actor's serialization context, preventing data races.
    ///
    /// - Parameters:
    ///   - string: The HTML string to parse.
    ///   - extract: A closure that takes the parsed `XMLDocument` and returns a `Sendable` value.
    /// - Returns: The value returned by the `extract` closure.
    /// - Throws: Rethrows any `XMLError` from parsing or any error thrown by the `extract` closure,
    ///   wrapping the latter in `XMLError.userTransformError`.
    public func parseHTMLAndExtract<T: Sendable>(
        string: String,
        extract: (XMLDocument) throws -> T
    ) async throws(XMLError) -> T {
        do {
            let doc = try parseHTML(string: string)
            return try extract(doc)
        } catch let error as XMLError {
            throw error
        } catch {
            throw XMLError.userTransformError(
                message: "The user-provided transform closure failed: \(error)")
        }
    }
}
