import CLibXML2

/// Configures the behavior of a `StreamParser`.
@frozen
public struct StreamParserOptions: Sendable {
    /// A set of `ParsingOptions` flags to control the underlying `libxml2` parser's behavior.
    public var flags: ParsingOptions

    /// If `true`, the parser will use the HTML parser instead of the XML parser. Defaults to `false`.
    public var isHTML: Bool

    /// The size of the buffer used for reading data from a file stream. Defaults to 4 KB.
    public var chunkSize: ChunkSize

    /// Creates a new set of stream parsing options.
    ///
    /// - Parameters:
    ///   - flags: The `libxml2` parsing flags to use.
    ///   - isHTML: Whether to use the HTML or XML parser.
    ///   - chunkSize: The buffer size for file-based stream parsing.
    public init(
        flags: ParsingOptions = [],
        isHTML: Bool = false,
        chunkSize: ChunkSize = .kilobytes(4)
    ) {
        self.flags = flags
        self.isHTML = isHTML
        self.chunkSize = chunkSize
    }

    /// Default options for parsing XML.
    ///
    /// These options enable recovery from minor errors and suppress console warnings.
    public static let lenientXML = StreamParserOptions(
        flags: [.recover, .noError, .noWarning]
    )

    /// Default options for parsing HTML.
    ///
    /// These options enable recovery from malformed HTML and suppress console warnings.
    public static let lenientHTML = StreamParserOptions(
        flags: [.recover, .noError, .noWarning],
        isHTML: true
    )
}
