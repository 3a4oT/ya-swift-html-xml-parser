import CLibXML2

#if canImport(Darwin)
    import Darwin.C
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#elseif canImport(Android)
    import Android
#elseif os(Windows)
    import CRT
    import ucrt
    import WinSDK
#elseif os(WASI)
    import WASILibc
#endif

/// A memory-based parser that loads the entire document into memory.
/// This parser is non-copyable to ensure single ownership of parsing resources.
public struct MemoryParser: ~Copyable {
    private let options: MemoryParserOptions

    public init(options: MemoryParserOptions = .lenientXML) {
        self.options = options
    }

    /// Parses an XML or HTML document from a byte span.
    ///
    /// - Parameter bytes: A `Span` over the byte buffer containing the document.
    /// - Returns: A `XMLDocument` representing the parsed document.
    /// - Throws: `XMLError` if parsing fails.
    func parse(bytes: borrowing Span<UInt8>) throws(XMLError) -> XMLDocument {
        guard bytes.count <= Int32.max else {
            throw XMLError.parsingError(
                message:
                "Input data is too large. The maximum size for memory-based parsing is \(Int32.max) bytes."
            )
        }

        let docPtr: xmlDocPtr? =
            if self.options.isHTML {
                bytes.withUnsafeBufferPointer { buffer in
                    htmlReadMemory(
                        buffer.baseAddress, Int32(buffer.count), nil, nil, self.options.flags.rawValue
                    )
                }
            } else {
                bytes.withUnsafeBufferPointer { buffer in
                    xmlReadMemory(
                        buffer.baseAddress, Int32(buffer.count), nil, nil, self.options.flags.rawValue
                    )
                }
            }

        guard let doc = docPtr else {
            throw XMLError.parsingError(message: self.getLastError())
        }

        return XMLDocument(doc)
    }

    /// Parse XML/HTML from a String.
    /// - Parameter string: The string to parse. This parameter is consumed for optimal performance.
    /// - Note: This method is NOT thread-safe. libxml2 uses global state during parsing.
    public func parse(string: consuming String) throws(XMLError) -> XMLDocument {
        do {
            return try string.withUTF8 { buffer in
                return try self.parse(bytes: Span(_unsafeElements: buffer))
            }
        } catch {
            // Since `parse(bytes:)` is typed to throw XMLError, any other
            // error here would be from `withUTF8`, which is unexpected.
            throw XMLError.internalInconsistency(message: "Failed to process string with UTF-8: \(error)")
        }
    }

    /// Parse XML/HTML from a file.
    /// - Note: This method is NOT thread-safe. libxml2 uses global state during parsing.
    public func parseFile(at path: String) throws(XMLError) -> XMLDocument {
        // Use the C `access` function to check for read permissions.
        guard access(path, R_OK) == 0 else {
            throw XMLError.fileNotFound(path: path)
        }

        let docPtr: xmlDocPtr? =
            if self.options.isHTML {
                htmlReadFile(path, nil, self.options.flags.rawValue)
            } else {
                xmlReadFile(path, nil, self.options.flags.rawValue)
            }

        guard let doc = docPtr else {
            throw XMLError.parsingError(message: self.getLastError())
        }

        return XMLDocument(doc)
    }

    private func getLastError() -> String {
        let error = xmlGetLastError()
        defer { xmlResetLastError() }

        guard let err = error else {
            return "Unknown parsing error"
        }

        return String(cString: err.pointee.message).trimmingWhitespace()
    }
}

// MARK: - Public API

/// Parses an XML string into a document using the specified options.
///
/// By default, this function uses `.strict` parsing, which will throw an error
/// on any well-formedness issue. To parse potentially malformed XML,
/// you can provide different options.
///
/// - Parameters:
///   - string: The XML string to parse. This parameter is consumed for optimal performance.
///   - options: The parsing options to use. Defaults to `.strict`.
/// - Returns: A parsed `XMLDocument`.
/// - Throws: `XMLError` if parsing fails according to the provided options.
public func parseXML(string: consuming String, options: MemoryParserOptions = .strict) throws(XMLError)
    -> XMLDocument {
    let parser = MemoryParser(options: options)
    return try parser.parse(string: string)
}

/// Parses an HTML string into a document using the specified options.
///
/// By default, this function uses `.lenientHTML` parsing, which is lenient and
/// designed to handle common well-formedness issues, similar to a web browser.
///
/// - Parameters:
///   - string: The HTML string to parse. This parameter is consumed for optimal performance.
///   - options: The parsing options to use. Defaults to `.lenientHTML`.
/// - Returns: A parsed `XMLDocument`.
/// - Throws: `XMLError` if parsing fails according to the provided options.
public func parseHTML(string: consuming String, options: MemoryParserOptions = .lenientHTML) throws(XMLError)
    -> XMLDocument {
    let parser = MemoryParser(options: options)
    return try parser.parse(string: string)
}
