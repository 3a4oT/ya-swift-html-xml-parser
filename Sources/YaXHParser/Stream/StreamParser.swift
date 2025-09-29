import CLibXML2
import LibXMLTrampolines

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

/// A stream-based parser that processes documents incrementally
/// - Warning: This class is NOT thread-safe. libxml2 uses global state and callbacks.
/// ## Design note
///
/// libxml2 invokes C callbacks.  A tiny C layer in `LibXMLTrampolines.c` forwards
/// each callback to a global Swift @_cdecl function (see `StreamParserTrampolines.swift`).
/// That global function looks up the current `StreamParser` instance and calls
/// `deliver(_:)` below.
///
/// To avoid paying the cost of opening an `any StreamEventHandler` existential on
/// *every* SAX event, the initializer captures the concrete handler once into a
/// closure stored in `sink`.  From that point on every event dispatch is just a
/// direct closure call (≈ 6 ns on Apple Silicon) instead of the 25–30 ns
/// existential/witness-table path.
///
/// ### Why we can’t simply make `StreamParser` generic
/// A generic type parameter `H` would have to be captured by every C-callable
/// trampoline closure.  In Swift 6.1 closures that capture generic parameters
/// **cannot** be turned into a `@convention(c)` function pointer—the compiler
/// emits the diagnostic "a C function pointer cannot be formed from a closure
/// that captures generic parameters".  Until that restriction is lifted
/// a non-generic parser plus
/// this trampoline layer is the highest-performance design that compiles.
public final class StreamParser {
    private var context: xmlParserCtxtPtr?
    private let sink: (StreamEvent) -> Void
    private let options: StreamParserOptions
    private var saxHandler: UnsafeMutablePointer<xmlSAXHandler>?
    private var buffer: [UInt8]

    public init(handler: any StreamEventHandler, options: StreamParserOptions = .lenientXML)
        throws(XMLError) {
        let chunkSize = options.chunkSize.valueInBytes
        guard chunkSize <= Int32.max else {
            throw XMLError.parsingError(
                message: "Chunk size is too large. The maximum chunk size is \(Int32.max) bytes.")
        }
        self.sink = { [weak h = handler] event in
            h?.handleEvent(event)
        }
        self.options = options
        self.buffer = [UInt8](repeating: 0, count: chunkSize)
    }

    deinit {
        if let context {
            if options.isHTML {
                htmlFreeParserCtxt(context)
            } else {
                xmlFreeParserCtxt(context)
            }
        }
        if let saxHandler {
            free(saxHandler)
        }
    }

    // MARK: - Trampoline entry point
    /// Forwards an event from the C trampolines into the captured `sink` closure.
    ///
    /// - Note: This method is kept **internal** (not `@inlinable`) so it can
    ///   freely access the private `sink` property without exposing that detail
    ///   outside the module.
    /// - Parameter event: The `StreamEvent` produced by libxml2.
    func deliver(_ event: StreamEvent) {
        self.sink(event)
    }

    /// Parse data from a byte buffer
    /// - Note: This method is NOT thread-safe. libxml2 uses global state during parsing.
    /// - Parameter bytes: A buffer containing a chunk of the XML/HTML document.
    /// - Throws: `XMLError` on failure.
    public func parse(bytes: UnsafeBufferPointer<UInt8>) throws(XMLError) {
        try self.initializeContext()
        try self.parseChunk(bytes)
        try self.finalize()
    }

    /// Parse data from a file
    /// - Note: This method is NOT thread-safe. libxml2 uses global state during parsing.
    /// - Parameter path: The file system path to the document.
    /// - Throws: `XMLError` on failure, such as if the file cannot be opened.
    public func parseFile(at path: String) throws(XMLError) {
        try self.initializeContext()

        guard let file = fopen(path, "r") else {
            throw XMLError.fileNotFound(path: path)
        }
        defer { fclose(file) }

        while true {
            let bytesRead = fread(&self.buffer, 1, self.buffer.count, file)
            guard bytesRead > 0 else {
                if ferror(file) != 0 {
                    throw XMLError.fileReadError(path: path)
                }
                break
            }

            do {
                try self.buffer.withUnsafeBufferPointer { bufferPtr in
                    let chunk = UnsafeBufferPointer(start: bufferPtr.baseAddress, count: bytesRead)
                    try self.parseChunk(chunk)
                }
            } catch {
                throw XMLError.internalInconsistency(
                    message: "An unexpected error occurred while processing a file chunk: \(error)")
            }
        }

        try self.finalize()
    }

    // MARK: - Private Methods

    private func initializeContext() throws(XMLError) {
        if self.context == nil {
            self.saxHandler = UnsafeMutablePointer<xmlSAXHandler>.allocate(capacity: 1)
            libxml_install_swift_trampolines(self.saxHandler)
            self.context = xmlCreatePushParserCtxt(
                self.saxHandler,
                UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
                nil,
                0,
                nil
            )
        }
    }

    private func parseChunk(_ bytes: UnsafeBufferPointer<UInt8>) throws(XMLError) {
        guard bytes.count <= Int32.max else {
            throw XMLError.parsingError(
                message: "Chunk data is too large. The maximum chunk size is \(Int32.max) bytes.")
        }
        guard let context else {
            throw XMLError.parsingError(message: "Parser context not initialized.")
        }

        let result = bytes.withMemoryRebound(to: CChar.self) { charBuffer -> Int32 in
            let ptr = UnsafeMutablePointer(mutating: charBuffer.baseAddress)
            return xmlParseChunk(context, ptr, Int32(charBuffer.count), 0)
        }

        if result != 0 {
            let error = xmlCtxtGetLastError(context)
            let errorMessage =
                error.flatMap { String(cString: $0.pointee.message) } ?? "Unknown stream parsing error"
            throw XMLError.parsingError(message: errorMessage.trimmingWhitespace())
        }
    }

    private func finalize() throws(XMLError) {
        guard let context else {
            return
        }

        let result = xmlParseChunk(context, nil, 0, 1) // Final chunk
        if result != 0 {
            let error = xmlCtxtGetLastError(context)
            let errorMessage =
                error.flatMap { String(cString: $0.pointee.message) }
                    ?? "Unknown stream parsing error during finalization"
            throw XMLError.parsingError(message: errorMessage.trimmingWhitespace())
        }

        xmlFreeParserCtxt(context)
        self.context = nil

        if let saxHandler {
            free(saxHandler)
            self.saxHandler = nil
        }
    }
}
