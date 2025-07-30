import CLibXML2

extension XMLDocument {
  /// Selects nodes from the document using a CSS selector.
  ///
  /// - Parameter selector: A CSS selector string (e.g., "div#main p.intro").
  /// - Returns: An `XMLNodeSet` containing the matched nodes.
  /// - Throws: `XMLError.css` if the selector is invalid, or `XMLError.xpath` if the underlying query fails.
  public func select(_ selector: String) throws(XMLError) -> XMLNodeSet {
    do {
      let xpath = try translateCSSToXPath(selector, relative: false)
      let nodes = try self.xpath(xpath)
      return XMLNodeSet(nodes)  // Correctly wrap the result
    } catch let error as CSSError {
      // Catch the specific error from the translator first
      throw XMLError.css(error)
    } catch {
      // `self.xpath` already throws XMLError, so other errors would be unexpected.
      throw XMLError.internalInconsistency(
        message: "An unexpected error occurred during CSS selection: \(error)")
    }
  }

  /// Intelligently extracts all URLs from the entire document.
  ///
  /// - Parameter options: An `OptionSet` specifying which tags to search for URLs. Defaults to `.all`.
  /// - Returns: An array of strings containing all found URLs.
  /// - Throws: `XMLError` if the underlying query fails.
  public func urls(from options: URLTagOptions = .all) throws(XMLError) -> [String] {
    guard !options.isEmpty else { return [] }
    return try self.select(options.selector).urls()
  }
}

extension XMLNode {
  /// Selects descendant nodes from the current node using a CSS selector.
  ///
  /// - Parameter selector: A CSS selector string.
  /// - Returns: An `XMLNodeSet` containing the matched nodes.
  /// - Throws: `XMLError` if the underlying XPath query fails.
  public func select(_ selector: String) throws(XMLError) -> XMLNodeSet {
    guard let doc = self.nodePtr.pointee.doc else {
      return XMLNodeSet([])
    }

    let xpath: String
    do {
      xpath = try translateCSSToXPath(selector, relative: true)
    } catch let cssError {  // No need for 'as CSSError' due to typed throws
      // The compiler knows this is a CSSError. Wrap it in the parent XMLError type.
      throw XMLError.css(cssError)
    }

    let context = xmlXPathNewContext(doc)
    defer { xmlXPathFreeContext(context) }

    let mutableNodePtr = UnsafeMutablePointer(mutating: self.nodePtr)
    xmlXPathSetContextNode(mutableNodePtr, context)

    let result = xpath.withCString { cString -> xmlXPathObjectPtr? in
      cString.withMemoryRebound(to: xmlChar.self, capacity: xpath.utf8.count) { xmlString in
        xmlXPathEvalExpression(xmlString, context)
      }
    }

    guard let xpathObject = result else {
      throw XMLError.xpath(message: "XPath query for CSS selector failed: '\(selector)'")
    }
    defer { xmlXPathFreeObject(xpathObject) }

    guard let nodes = xpathObject.pointee.nodesetval else {
      return XMLNodeSet([])
    }

    let nodeCount = Int(nodes.pointee.nodeNr)
    var results: [XMLNode] = []
    results.reserveCapacity(nodeCount)

    for i in 0..<nodeCount {
      if let nodePtr = nodes.pointee.nodeTab[i] {
        results.append(XMLNode(nodePtr))
      }
    }

    return XMLNodeSet(results)
  }

  /// Intelligently extracts all URLs from the descendants of this node.
  ///
  /// - Parameter options: An `OptionSet` specifying which tags to search for URLs. Defaults to `.all`.
  /// - Returns: An array of strings containing all found URLs.
  /// - Throws: `XMLError` if the underlying query fails.
  public func urls(from options: URLTagOptions = .all) throws(XMLError) -> [String] {
    guard !options.isEmpty else { return [] }
    return try self.select(options.selector).urls()
  }
}
