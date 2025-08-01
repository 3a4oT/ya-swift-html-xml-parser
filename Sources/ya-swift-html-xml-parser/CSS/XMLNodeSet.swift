/// A collection of `XMLNode` objects, typically the result of a query.
///
/// `XMLNodeSet` provides a convenient, array-like interface for working with
/// a list of nodes. It also allows for further querying on the result set.
public struct XMLNodeSet: RandomAccessCollection {
    public typealias Element = XMLNode
    public typealias Index = Int

    private let nodes: [XMLNode]

    /// Creates a node set from an array of nodes.
    init(_ nodes: [XMLNode]) {
        self.nodes = nodes
    }

    // MARK: - Collection Conformance

    public var startIndex: Int { self.nodes.startIndex }
    public var endIndex: Int { self.nodes.endIndex }

    public func index(after i: Int) -> Int {
        self.nodes.index(after: i)
    }

    public subscript(position: Int) -> XMLNode {
        self.nodes[position]
    }

    // MARK: - Convenience Accessors

    /// The first node in the set, or `nil` if the set is empty.
    public var first: XMLNode? {
        self.nodes.first
    }

    /// The text content of all nodes in the set, concatenated together.
    public var text: String {
        self.nodes.map(\.text).joined()
    }

    // MARK: - Querying

    /// Selects descendant nodes from each node in the current set using a CSS selector.
    ///
    /// - Parameter selector: A CSS selector string.
    /// - Returns: A new `XMLNodeSet` containing all matched nodes from all nodes in the current set.
    /// - Throws: `XMLError` if the underlying query fails on any node.
    public func select(_ selector: String) throws(XMLError) -> XMLNodeSet {
        var results: [XMLNode] = []
        for node in self.nodes {
            try results.append(contentsOf: node.select(selector))
        }
        return XMLNodeSet(results)
    }

    // MARK: - Data Extraction

    /// Extracts the value of a given attribute from every node in the set.
    /// - Parameter name: The name of the attribute to extract (e.g., "href", "src").
    /// - Returns: An array of strings containing the attribute values. Nodes without the attribute are ignored.
    public func attributes(_ name: String) -> [String] {
        return self.nodes.compactMap { $0.getAttribute(name) }
    }

    /// Intelligently extracts all URLs from the nodes in the set.
    ///
    /// This method knows which attributes contain URLs for common HTML tags:
    /// - `<a>`, `<link>`: `href`
    /// - `<img>`, `<video>`, `<audio>`, `<script>`, `<source>`, `<iframe>`: `src`
    ///
    /// - Returns: An array of strings containing all found URLs.
    public func urls() -> [String] {
        return self.nodes.flatMap { node -> [String] in
            switch node.name {
            case "a", "link":
                if let url = node.getAttribute("href") {
                    return [url]
                }
            case "img", "video", "audio", "script", "source", "iframe":
                if let url = node.getAttribute("src") {
                    return [url]
                }
            default:
                break
            }
            return []
        }
    }
}
