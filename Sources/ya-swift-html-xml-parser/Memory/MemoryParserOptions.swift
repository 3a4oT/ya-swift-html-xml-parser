import CLibXML2

/// Options for configuring a `MemoryParser`.
@frozen
public struct MemoryParserOptions: Sendable {
  public var flags: ParsingOptions
  public var isHTML: Bool

  public init(
    flags: ParsingOptions = [],
    isHTML: Bool = false
  ) {
    self.flags = flags
    self.isHTML = isHTML
  }

  /// Default options for parsing XML.
  ///
  /// This configuration is lenient and will attempt to recover from well-formedness errors.
  /// It suppresses warning and error reporting to the console. This is suitable for processing
  /// XML that may not be strictly valid but is still parsable.
  public static let lenientXML = MemoryParserOptions(
    flags: [.recover, .noError, .noWarning]
  )

  /// Default options for parsing HTML.
  ///
  /// This configuration is lenient, designed to handle common HTML well-formedness issues
  /// in a manner similar to a web browser. It suppresses warning and error reporting.
  public static let lenientHTML = MemoryParserOptions(
    flags: [.recover, .noError, .noWarning],
    isHTML: true
  )

  /// A strict set of options for parsing XML.
  ///
  /// This configuration does **not** recover from errors and enables pedantic error checking.
  /// It is suitable for validation scenarios where the XML must be perfectly well-formed.
  /// Any parsing error will result in a thrown `XMLError`.
  public static let strict = MemoryParserOptions(
    flags: [.noError, .noWarning, .pedantic]
  )
}
