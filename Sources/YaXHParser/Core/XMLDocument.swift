import CLibXML2

/// A document that owns the underlying libxml2 document
/// - Warning: This class is NOT thread-safe. libxml2 uses global state.
public final class XMLDocument {
    private let docPtr: xmlDocPtr

    @inline(__always)
    init(_ docPtr: xmlDocPtr) {
        self.docPtr = docPtr
    }

    deinit {
        xmlFreeDoc(docPtr)
    }

    /// Access the root element of the document
    /// - Warning: The returned YAXMLNode is only valid while this XMLDocument exists
    @inline(__always)
    public var rootElement: XMLNode? {
        guard let root = xmlDocGetRootElement(docPtr) else {
            return nil
        }
        return XMLNode(root)
    }

    /// Queries the document using an XPath expression.
    ///
    /// XPath is a powerful query language for selecting nodes from an XML or HTML document.
    ///
    /// Example:
    /// ```swift
    /// // Find all `<a>` tags anywhere in the document
    /// let links = try doc.xpath("//a")
    ///
    /// // Find all `<div>` tags with a `class` attribute of 'content'
    /// let contentDivs = try doc.xpath("//div[@class='content']")
    /// ```
    ///
    /// - Parameter query: The XPath query string.
    /// - Returns: An array of `XMLNode` objects that match the query.
    /// - Throws: `XMLError` if the XPath query is invalid or fails to execute.
    public func xpath(_ query: String) throws(XMLError) -> [XMLNode] {
        // 1. Create a context for the XPath query
        guard let context = xmlXPathNewContext(docPtr) else {
            throw XMLError.internalInconsistency(message: "Failed to create XPath context.")
        }
        defer { xmlXPathFreeContext(context) }

        // 2. Evaluate the XPath expression
        let result = query.withCString { cString -> xmlXPathObjectPtr? in
            // Cast the C string to xmlChar*, which is what libxml2 expects
            return cString.withMemoryRebound(to: xmlChar.self, capacity: query.utf8.count) { xmlString in
                xmlXPathEvalExpression(xmlString, context)
            }
        }

        guard let xpathObject = result else {
            let error = xmlGetLastError()
            let message =
                (error != nil) ? String(cString: error!.pointee.message) : "XPath query failed: '\(query)'"
            throw XMLError.xpath(message: message)
        }
        defer { xmlXPathFreeObject(xpathObject) }

        // 3. Extract the nodes from the result set
        guard let nodes = xpathObject.pointee.nodesetval else {
            // This can happen with valid queries that don't return a node-set
            // (e.g., `count(//a)`). Returning an empty array is appropriate.
            return []
        }

        let nodeCount = Int(nodes.pointee.nodeNr)
        var results: [XMLNode] = []
        results.reserveCapacity(nodeCount)

        for i in 0 ..< nodeCount {
            if let nodePtr = nodes.pointee.nodeTab[i] {
                results.append(XMLNode(nodePtr))
            }
        }

        return results
    }
}
