import CLibXML2

/// A type-safe representation of the options for the XML/HTML parser,
/// providing a Swift-native alternative to C-style bitmasks.
@frozen
public struct ParsingOptions: OptionSet, Sendable {
  public let rawValue: Int32

  public init(rawValue: Int32) {
    self.rawValue = rawValue
  }

  /// Recovers from errors.
  public static let recover = ParsingOptions(rawValue: Int32(XML_PARSE_RECOVER.rawValue))

  /// Suppresses error reports.
  public static let noError = ParsingOptions(rawValue: Int32(XML_PARSE_NOERROR.rawValue))

  /// Suppresses warning reports.
  public static let noWarning = ParsingOptions(rawValue: Int32(XML_PARSE_NOWARNING.rawValue))

  /// Applies pedantic error reporting.
  public static let pedantic = ParsingOptions(rawValue: Int32(XML_PARSE_PEDANTIC.rawValue))

  /// Removes blank nodes.
  public static let noBlanks = ParsingOptions(rawValue: Int32(XML_PARSE_NOBLANKS.rawValue))

  /// Forbids network access when parsing.
  public static let noNetwork = ParsingOptions(rawValue: Int32(XML_PARSE_NONET.rawValue))

  /// Compacts small text nodes.
  public static let compact = ParsingOptions(rawValue: Int32(XML_PARSE_COMPACT.rawValue))
}
