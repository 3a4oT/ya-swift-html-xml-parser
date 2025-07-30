/// Errors that can occur during CSS selector parsing and translation.
public enum CSSError: Error, Sendable, Equatable {
  /// Thrown when an XPath query generated from a CSS selector fails to execute.
  case queryFailed(selector: String, underlyingErrorMessage: String)

  /// Thrown when a CSS selector contains syntax that is not supported by the translator.
  case unsupportedSelector(selector: String, message: String)
}
