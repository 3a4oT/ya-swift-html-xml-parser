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

/// A stream-based parser that processes documents incrementally
/// - Warning: This class is NOT thread-safe. libxml2 uses global state and callbacks.
public final class StreamParser {
    private var context: xmlParserCtxtPtr?
    fileprivate let handler: any StreamEventHandler
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
        self.handler = handler
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
            self.saxHandler = createSAXHandler()
            self.context = xmlCreatePushParserCtxt(
                self.saxHandler, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()), nil, 0,
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

private func createSAXHandler() -> UnsafeMutablePointer<xmlSAXHandler> {
    let saxHandler = UnsafeMutablePointer<xmlSAXHandler>.allocate(capacity: 1)
    saxHandler.initialize(to: xmlSAXHandler())

    saxHandler.pointee.startDocument = { userData in
        guard let userData else { return }
        let parser = Unmanaged<StreamParser>.fromOpaque(userData).takeUnretainedValue()
        parser.handler.handleEvent(.startDocument)
    }

    saxHandler.pointee.endDocument = { userData in
        guard let userData else { return }
        let parser = Unmanaged<StreamParser>.fromOpaque(userData).takeUnretainedValue()
        parser.handler.handleEvent(.endDocument)
    }

    saxHandler.pointee.startElement = { userData, name, attributes in
        guard let userData, let name else { return }
        let parser = Unmanaged<StreamParser>.fromOpaque(userData).takeUnretainedValue()
        let elementName = String(cString: name)

        var attrs: [(String, String)] = []
        if let attributes {
            var i = 0
            while let namePtr = attributes[i] {
                let valuePtr = attributes[i + 1]
                let name = String(cString: namePtr)
                let value = valuePtr.map { String(cString: $0) } ?? ""
                attrs.append((name, value))
                i += 2
            }
        }
        parser.handler.handleEvent(.startElement(name: elementName, attributes: attrs))
    }

    saxHandler.pointee.endElement = { userData, name in
        guard let userData, let name else { return }
        let parser = Unmanaged<StreamParser>.fromOpaque(userData).takeUnretainedValue()
        parser.handler.handleEvent(.endElement(name: String(cString: name)))
    }

    saxHandler.pointee.characters = { userData, ch, len in
        guard let userData, let ch else { return }
        let parser = Unmanaged<StreamParser>.fromOpaque(userData).takeUnretainedValue()
        let characters = String(
            decoding: UnsafeBufferPointer(start: ch, count: Int(len)), as: UTF8.self
        )
        parser.handler.handleEvent(.characters(characters))
    }

    saxHandler.pointee.comment = { userData, value in
        guard let userData, let value else { return }
        let parser = Unmanaged<StreamParser>.fromOpaque(userData).takeUnretainedValue()
        parser.handler.handleEvent(.comment(String(cString: value)))
    }

    saxHandler.pointee.cdataBlock = { userData, value, len in
        guard let userData, let value else { return }
        let parser = Unmanaged<StreamParser>.fromOpaque(userData).takeUnretainedValue()
        let cdata = String(decoding: UnsafeBufferPointer(start: value, count: Int(len)), as: UTF8.self)
        parser.handler.handleEvent(.cdata(cdata))
    }

    saxHandler.pointee.processingInstruction = { userData, target, data in
        guard let userData, let target else { return }
        let parser = Unmanaged<StreamParser>.fromOpaque(userData).takeUnretainedValue()
        let targetString = String(cString: target)
        let dataString = data.map { String(cString: $0) }
        parser.handler.handleEvent(.processingInstruction(target: targetString, data: dataString))
    }

    let cError: @convention(c) (UnsafeMutableRawPointer?, UnsafePointer<CChar>?) -> Void = {
        userData, msg in
        guard let userData, let msg else { return }
        let message = String(cString: msg)
        let parser = Unmanaged<StreamParser>.fromOpaque(userData).takeUnretainedValue()
        parser.handler.handleEvent(.error(message.trimmingWhitespace()))
    }
    saxHandler.pointee.error = unsafeBitCast(cError, to: errorSAXFunc.self)

    return saxHandler
}
