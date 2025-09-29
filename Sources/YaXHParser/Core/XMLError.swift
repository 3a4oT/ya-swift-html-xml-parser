public enum XMLError: Error, Sendable {
    case documentCreation
    case invalidData
    case fileNotFound(path: String)
    case fileReadError(path: String)
    case xpath(message: String)
    case css(CSSError)
    /// Thrown when a recursive operation reaches the specified depth limit before completion.
    case depthLimitExceeded(limit: Int)
    /// Thrown when a parsing error occurs, often in the stream parser.
    case parsingError(message: String)
    /// An internal logic error occurred that should not be possible.
    case internalInconsistency(message: String)
    /// Thrown when a user-provided closure in the ParsingService fails.
    case userTransformError(message: String)
}
