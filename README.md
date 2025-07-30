# YaSwiftXML

A high-performance, Foundation-free Swift wrapper for libxml2, providing safe and efficient XML/HTML parsing capabilities.

## Features

- 🚀 **High Performance**: Direct libxml2 wrapper with minimal overhead
- 🎯 **Foundation-Free**: Pure Swift implementation without Foundation dependencies
- 📦 **Swift Package Manager**: Easy integration with SPM
- 🔄 **Two Parsing Modes**:
  - **Memory-based**: Load entire documents into memory
  - **Stream-based**: Process large documents incrementally
- 🛡️ **Type Safety**: Swift-native error handling and type safety
- 📱 **Cross-Platform**: Works on macOS, iOS, tvOS, watchOS, and visionOS

## Requirements

- Swift 6.2+
- libxml2 (usually pre-installed on Apple platforms)
- macOS 15.0+ / iOS 18.0+ / tvOS 18.0+ / watchOS 11.0+ / visionOS 2.0+

## Installation

### Swift Package Manager

Add this to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/YaSwiftXML.git", from: "1.0.0")
]
```

## Usage

### Memory-Based Parsing

```swift
import YaSwiftXML

// Parse XML
let xml = "<root><item>Hello</item></root>"
let doc = try parseXML(string: xml)

if let root = doc.rootElement {
    print("Root name: \(root.name ?? "unknown")")
    
    root.forEachChild { child in
        if child.type == .element {
            print("Child: \(child.name ?? "") = \(child.content ?? "")")
        }
    }
}

// Parse HTML
let html = "<html><body><h1>Title</h1></body></html>"
let htmlDoc = try parseHTML(string: html)
```

### Stream-Based Parsing

```swift
import YaSwiftXML

class MyEventHandler: StreamEventHandler {
    func handleEvent(_ event: StreamEvent) {
        switch event {
        case .startElement(let name, let attributes):
            print("Start element: \(name)")
            for (key, value) in attributes {
                print("  \(key) = \(value)")
            }
        case .characters(let text):
            print("Text: \(text)")
        default:
            break
        }
    }
}

let handler = MyEventHandler()
let parser = StreamParser(handler: handler)

// Parse from string
let xmlData = Array("<root><item>Test</item></root>".utf8)
try xmlData.withUnsafeBufferPointer { buffer in
    try parser.parse(bytes: buffer)
}

// Parse from file
try parser.parseFile(at: "/path/to/file.xml")
```

## Thread Safety

⚠️ **WARNING**: This library is **NOT thread-safe**. libxml2 uses global state during parsing operations.

- Do not share `XMLDocument`, `MemoryParser`, or `StreamParser` instances between threads
- Do not perform concurrent parsing operations
- Use appropriate synchronization if you need to parse from multiple threads

## API Overview

### Core Types

- `XMLDocument`: Represents a parsed XML/HTML document
- `XMLNode`: Represents a node in the document tree
- `XMLNodeType`: Enumeration of node types (element, text, comment, etc.)

### Parsing

- `parseXML(string:)`: Parse XML from a string
- `parseHTML(string:)`: Parse HTML from a string
- `MemoryParser`: Configurable memory-based parser
- `StreamParser`: SAX-style stream parser for large documents

### Error Handling

- `ParsingError`: Errors that can occur during parsing
  - `.encodingError`: String encoding issues
  - `.parsingFailed(String)`: Parse errors with description
  - `.streamError(String)`: Stream-specific errors

## Future Improvements

When Swift's lifetime dependency features are stabilized, we plan to:
- Add `Span` support for zero-copy string access
- Implement `~Escapable` types for better memory safety
- Provide async stream parsing with proper backpressure

## License

[Your License Here]

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. 