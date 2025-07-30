/// Represents the type of an XML node, corresponding to `libxml2`'s `xmlElementType`.
@frozen
public enum XMLNodeType: Int, Sendable {
  /// A node type that is not recognized or has not been determined.
  case unknown = 0
  /// An element node, e.g., `<item>`.
  case element = 1
  /// An attribute node, e.g., `id="123"`.
  case attribute = 2
  /// A text node, e.g., the content inside an element.
  case text = 3
  /// A CDATA section node, e.g., `<![CDATA[raw text]]>`.
  case cdataSection = 4
  /// An entity reference node, e.g., `&amp;`.
  case entityRef = 5
  /// An entity declaration node, e.g., `<!ENTITY name "value">`.
  case entity = 6
  /// A processing instruction node, e.g., `<?target content?>`.
  case pi = 7
  /// A comment node, e.g., `<!-- A comment -->`.
  case comment = 8
  /// The document node itself, the root of the document tree.
  case document = 9
  /// A document type declaration (DTD) node, e.g., `<!DOCTYPE ...>`.
  case documentType = 10
  /// A document fragment node.
  case documentFrag = 11
  /// A notation declaration node in a DTD.
  case notation = 12
  /// An HTML document node.
  case htmlDocument = 13
  /// A DTD node.
  case dtd = 14
  /// An element declaration in a DTD.
  case elementDecl = 15
  /// An attribute declaration in a DTD.
  case attributeDecl = 16
  /// An entity declaration in a DTD.
  case entityDecl = 17
  /// A namespace declaration.
  case namespaceDecl = 18
  /// An XInclude start node.
  case xincludeStart = 19
  /// An XInclude end node.
  case xincludeEnd = 20
}
