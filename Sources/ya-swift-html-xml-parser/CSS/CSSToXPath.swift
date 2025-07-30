/// A lightweight, non-copyable parser that operates on a string's UTF8 bytes to avoid allocations.
/// It is declared private to this file as it is a specific implementation detail of the translator.
private struct SelectorTranslator: ~Copyable {
  private let source: String.UTF8View
  private var cursor: String.UTF8View.Index

  init(_ css: String) {
    self.source = css.utf8
    self.cursor = self.source.startIndex
  }

  // Character constants for readability and performance.
  private static let space = Character(" ").asciiValue!
  private static let comma = Character(",").asciiValue!
  private static let hash = Character("#").asciiValue!
  private static let dot = Character(".").asciiValue!
  private static let attributeStart = Character("[").asciiValue!

  private var isAtEnd: Bool { cursor == source.endIndex }
  private func peek() -> UInt8? { isAtEnd ? nil : source[cursor] }
  private mutating func advance() { if !isAtEnd { cursor = source.index(after: cursor) } }

  private mutating func skipWhitespace() {
    while let char = peek(), char == Self.space {
      advance()
    }
  }

  private mutating func parseIdentifier() -> Substring {
    let start = cursor
    while let char = peek(),
      (char >= 97 && char <= 122)  // a-z
        || (char >= 65 && char <= 90)  // A-Z
        || (char >= 48 && char <= 57)  // 0-9
        || char == 45
    {  // -
      advance()
    }
    return Substring(source[start..<cursor])
  }

  private mutating func parseComponent() throws(CSSError) -> String {
    var path = ""

    // Tag
    let startOfComponent = cursor
    if let char = peek(), (char >= 97 && char <= 122) || (char >= 65 && char <= 90) {
      path += parseIdentifier()
    } else {
      path += "*"
    }

    // ID, Classes, and other attributes
    while !isAtEnd {
      switch peek() {
      case Self.hash:  // #
        advance()
        let id = parseIdentifier()
        path += "[@id='\(id)']"
      case Self.dot:  // .
        advance()
        let `class` = parseIdentifier()
        path += "[contains(concat(' ', normalize-space(@class), ' '), ' \(`class`) ')]"
      case Self.attributeStart:  // [
        // For now, attribute selectors are not supported. Throw an error.
        throw CSSError.unsupportedSelector(
          selector: String(decoding: source, as: UTF8.self),
          message: "Attribute selectors (e.g., [href^='...']) are not supported.")
      default:
        if cursor == startOfComponent { advance() }
        return path
      }
    }
    return path
  }

  mutating func parse(relative: Bool) throws(CSSError) -> String {
    var xpathParts: [String] = []

    while !isAtEnd {
      skipWhitespace()

      var components: [String] = []
      // Using a for loop here instead of a while to avoid re-calculating `isAtEnd`
      // and to make the logic clearer.
      for _ in 0..<Int.max {
        skipWhitespace()
        if isAtEnd || peek() == Self.comma { break }
        try components.append(parseComponent())
        skipWhitespace()
      }

      if !components.isEmpty {
        let prefix = relative ? ".//" : "//"
        xpathParts.append(prefix + components.joined(separator: "//"))
      }

      if peek() == Self.comma {
        advance()
      } else {
        break  // No more groups to parse
      }
    }

    // Ensure we consumed the whole string
    skipWhitespace()
    if !isAtEnd {
      throw CSSError.unsupportedSelector(
        selector: String(decoding: source, as: UTF8.self),
        message: "Invalid or unsupported characters at the end of the selector.")
    }

    return xpathParts.joined(separator: " | ")
  }
}

/// A simple, CSS selector to XPath translator.
/// This is not a full CSS3 implementation, but it covers the most common cases.
/// It is optimized to minimize string allocations by operating on the UTF8 view of the selector.
func translateCSSToXPath(_ css: String, relative: Bool = false) throws(CSSError) -> String {
  var parser = SelectorTranslator(css)
  return try parser.parse(relative: relative)
}
