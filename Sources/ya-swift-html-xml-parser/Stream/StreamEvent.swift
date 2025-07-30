/// Event types emitted by the stream parser
public enum StreamEvent: Sendable {
  case startDocument
  case endDocument
  case startElement(name: String, attributes: [(String, String)])
  case endElement(name: String)
  case characters(String)
  case comment(String)
  case cdata(String)
  case processingInstruction(target: String, data: String?)
  case error(String)
}

/// Protocol for handling stream events
public protocol StreamEventHandler: AnyObject {
  /// Handle a stream event
  func handleEvent(_ event: StreamEvent)
}

/// A simple event handler that collects events
public class CollectingEventHandler: StreamEventHandler {
  private var events: [StreamEvent] = []

  public init() {}

  public func handleEvent(_ event: StreamEvent) {
    events.append(event)
  }

  public var collectedEvents: [StreamEvent] {
    return events
  }
}
