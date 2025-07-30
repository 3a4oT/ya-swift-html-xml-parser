import CLibXML2

/// An efficient, forward-only iterator and sequence for traversing a node's children.
public struct XMLNodeSequence: Sequence, IteratorProtocol {
  var current: xmlNodePtr?

  @inline(__always)
  internal init(current: xmlNodePtr?) {
    self.current = current
  }

  @inline(__always)
  public mutating func next() -> XMLNode? {
    guard let currentNode = current else { return nil }
    let result = XMLNode(currentNode)
    self.current = currentNode.pointee.next
    return result
  }
}
