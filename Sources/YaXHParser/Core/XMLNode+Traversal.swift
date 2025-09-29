import CLibXML2

extension XMLNode {
    /// Iterates over the direct children of this node.
    @inline(__always)
    public func forEachChild(_ body: (XMLNode) throws -> Void) rethrows {
        var childPtr = nodePtr.pointee.children
        while let currentChild = childPtr {
            try body(XMLNode(currentChild))
            childPtr = currentChild.pointee.next
        }
    }

    /// Finds all descendant nodes that match a given predicate, up to a specified depth.
    ///
    /// This method performs a non-recursive, depth-first search of the tree
    /// beneath the current node.
    ///
    /// - Parameter maxDepth: The maximum depth of descendant nodes to search. Defaults to 1000.
    /// - Parameter predicate: A closure that returns `true` for nodes that should be
    ///   included in the result.
    /// - Returns: An array of `XMLNode` objects that match the predicate.
    /// - Throws: `XMLError.depthLimitExceeded` if the traversal is stopped because it
    ///   reached the `maxDepth` limit while there were still deeper nodes to explore.
    @inline(__always)
    public func find(maxDepth: Int = 1000, where predicate: (XMLNode) -> Bool) throws(XMLError)
        -> [XMLNode] {
        var results: [XMLNode] = []
        var nodesToVisit: [(node: XMLNode, depth: Int)] = [(self, 0)]
        var hasMoreNodes = false

        while !nodesToVisit.isEmpty {
            let current = nodesToVisit.removeLast()

            if current.depth > maxDepth {
                hasMoreNodes = true
                continue
            }

            if predicate(current.node) {
                results.append(current.node)
            }

            let children = Array(current.node.children)
            for child in children.reversed() {
                nodesToVisit.append((child, current.depth + 1))
            }
        }

        if hasMoreNodes {
            throw XMLError.depthLimitExceeded(limit: maxDepth)
        }

        return results
    }

    /// Iterates over all attributes of this node.
    @inline(__always)
    public func forEachAttribute(_ body: (String, String) throws -> Void) rethrows {
        var attr = nodePtr.pointee.properties
        while let currentAttr = attr {
            if let namePtr = currentAttr.pointee.name,
               let valuePtr = xmlNodeListGetString(nodePtr.pointee.doc, currentAttr.pointee.children, 1) {
                let name = String(cString: namePtr)
                let value = String(cString: valuePtr)
                valuePtr.withMemoryRebound(to: CChar.self, capacity: 1) { ptr in
                    free(UnsafeMutableRawPointer(mutating: ptr))
                }
                try body(name, value)
            }
            attr = currentAttr.pointee.next
        }
    }
}
