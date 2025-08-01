import CLibXML2

/// A wrapper around libxml2's xmlNode
/// - Warning: This type holds a pointer to an XML node that is owned by XMLDocument.
///   Do not use after the XMLDocument is deallocated.
public struct XMLNode {
    let nodePtr: UnsafePointer<xmlNode>

    @inline(__always)
    init(_ nodePtr: UnsafePointer<xmlNode>) {
        self.nodePtr = nodePtr
    }

    @inline(__always)
    public var type: XMLNodeType {
        return XMLNodeType(rawValue: Int(self.nodePtr.pointee.type.rawValue)) ?? .unknown
    }

    @inline(__always)
    public var name: String? {
        guard let namePtr = nodePtr.pointee.name else { return nil }
        return String(cString: namePtr)
    }

    /// The text content of this node and all of its descendants, concatenated in document order.
    ///
    /// This property recursively traverses all child nodes and returns a single
    /// string containing all text content, similar to a web browser's `innerText`.
    /// It returns an empty string if the node has no text content.
    public var text: String {
        guard let contentPtr = xmlNodeGetContent(nodePtr) else { return "" }
        defer {
            // The result of xmlNodeGetContent must be freed with xmlFree
            contentPtr.withMemoryRebound(to: CChar.self, capacity: 1) { ptr in
                free(UnsafeMutableRawPointer(mutating: ptr))
            }
        }
        return String(cString: contentPtr)
    }

    /// The direct content of this node, which for an element node is the
    /// concatenated text of its direct children. For a text node, it's the text itself.
    @inline(__always)
    public var content: String? {
        // This is a separate implementation from .text, as it should NOT be recursive.
        // However, xmlNodeGetContent IS recursive. The correct function for non-recursive
        // text is xmlNodeListGetString.
        guard let child = nodePtr.pointee.children,
              let contentPtr = xmlNodeListGetString(nodePtr.pointee.doc, child, 1) else {
            return nil
        }
        defer {
            contentPtr.withMemoryRebound(to: CChar.self, capacity: 1) { ptr in
                free(UnsafeMutableRawPointer(mutating: ptr))
            }
        }
        return String(cString: contentPtr)
    }

    @inline(__always)
    public func getAttribute(_ name: String) -> String? {
        return name.withCString { nameCStr in
            guard let attrPtr = xmlGetProp(nodePtr, nameCStr) else { return nil }
            defer {
                attrPtr.withMemoryRebound(to: CChar.self, capacity: 1) { ptr in
                    free(UnsafeMutableRawPointer(mutating: ptr))
                }
            }
            return String(cString: attrPtr)
        }
    }

    /// A sequence of the direct children of this node.
    ///
    /// This property provides an efficient, forward-only sequence for iterating
    /// over the node's children. It avoids allocating an intermediate array.
    ///
    /// Example:
    /// ```
    /// for child in node.children where child.type == .element {
    ///     print(child.name)
    /// }
    /// ```
    @inline(__always)
    public var children: XMLNodeSequence {
        XMLNodeSequence(current: self.nodePtr.pointee.children)
    }
}
