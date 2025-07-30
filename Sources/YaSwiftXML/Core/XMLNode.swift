import CLibXML2

/// A wrapper around libxml2's xmlNode
/// - Warning: This type holds a pointer to an XML node that is owned by XMLDocument.
///   Do not use after the XMLDocument is deallocated.
public struct XMLNode {
    @usableFromInline
    internal let nodePtr: UnsafePointer<xmlNode>
    
    @inlinable
    init(_ nodePtr: UnsafePointer<xmlNode>) {
        self.nodePtr = nodePtr
    }
    
    @inlinable
    public var type: XMLNodeType {
        return XMLNodeType(rawValue: Int(nodePtr.pointee.type.rawValue)) ?? .unknown
    }
    
    @inlinable
    public var name: String? {
        guard let namePtr = nodePtr.pointee.name else { return nil }
        return String(cString: namePtr)
    }
    
    @inlinable
    public var content: String? {
        guard let contentPtr = xmlNodeGetContent(nodePtr) else { return nil }
        defer { 
            contentPtr.withMemoryRebound(to: CChar.self, capacity: 1) { ptr in
                free(UnsafeMutableRawPointer(mutating: ptr))
            }
        }
        return String(cString: contentPtr)
    }
    
    @inlinable
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
    
    @inlinable
    public func forEachChild(_ body: (XMLNode) throws -> Void) rethrows {
        var child = nodePtr.pointee.children
        while let currentChild = child {
            let childNode = XMLNode(currentChild)
            try body(childNode)
            child = currentChild.pointee.next
        }
    }
    
    @inlinable
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

public enum XMLNodeType: Int, Sendable {
    case unknown = 0
    case element = 1
    case attribute = 2
    case text = 3
    case cdataSection = 4
    case entityRef = 5
    case entity = 6
    case pi = 7
    case comment = 8
    case document = 9
    case documentType = 10
    case documentFrag = 11
    case notation = 12
    case htmlDocument = 13
    case dtd = 14
    case elementDecl = 15
    case attributeDecl = 16
    case entityDecl = 17
    case namespaceDecl = 18
    case xincludeStart = 19
    case xincludeEnd = 20
}

/// A document that owns the underlying libxml2 document
/// - Warning: This class is NOT thread-safe. libxml2 uses global state.
public final class XMLDocument {
    private let docPtr: xmlDocPtr
    
    init(_ docPtr: xmlDocPtr) {
        self.docPtr = docPtr
    }
    
    deinit {
        xmlFreeDoc(docPtr)
    }
    
    /// Access the root element of the document
    /// - Warning: The returned YAXMLNode is only valid while this XMLDocument exists
    public var rootElement: XMLNode? {
        guard let root = xmlDocGetRootElement(docPtr) else {
            return nil
        }
        return XMLNode(root)
    }
} 