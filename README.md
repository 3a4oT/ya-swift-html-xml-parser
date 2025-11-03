# YaXHParser

A tiny, modern Swift wrapper for `libxml2` that makes XML & HTML parsing easy, taking a-dvantage of the latest Swift features.

[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS%20%7C%20Linux-lightgrey.svg)](https://swift.org)
[![SPM compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)

## Features

- **Foundation-Free**: Lightweight and portable, with no dependencies on Foundation.
- **High-Level Data Extraction**: Easily extract all URLs from a document or selection with `doc.urls(from:)`.
- **Powerful Queries**: Use convenient CSS selectors or the full power of XPath on both HTML and XML.
- **Experimental Stream Parsing**: Process very large documents (e.g., XML data feeds) with a low memory footprint.
- **Simple API**: Get started in seconds with `parseHTML(string:)` and `parseXML(string:)`.
- **Experimental Concurrency Support**: Includes a `ParsingService` actor for uncommon scenarios requiring thread-safe parsing.

## Build Requirements

- Swift 6.2+
- `libxml2`. This library is a wrapper around the C library `libxml2`.
  - On Apple platforms (macOS, iOS, tvOS, watchOS, visionOS), this is provided by the system and no action is needed.
  - On Ubuntu, you must install the development package: `sudo apt-get install libxml2-dev`. Other distributions may require a similar package (e.g., `libxml2-devel` on Fedora).

## Supported Platforms

- Darwin (macOS, iOS, tvOS, watchOS, visionOS)
- Linux (Ubuntu). Other distributions like Amazon Linux 2 and Fedora are not officially tested but may work.

## Installation

Add YaXHParser as a dependency to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/3a4oT/ya-swift-html-xml-parser.git", from: "0.1.0")
]
```

## Usage

### HTML Parsing

Use `parseHTML(string:)` to work with HTML documents. This function is lenient by default, handling malformed or incomplete HTML just like a web browser.

#### Example: Scraping Media URLs

A common task in web scraping is to find all URLs for media, links, or embedded content. The `urls(from:)` method simplifies this. It accepts an `OptionSet` called `URLTagOptions` that lets you specify exactly which tags to extract URLs from.

This is especially useful for building scrapers for media sites (e.g., finding movie trailers or image galleries).

```swift
import YaXHParser

let mediaHTML = """
<article>
  <h1>My Movie Review</h1>
  <a href="/reviews/home">Home</a>
  <img src="/poster.jpg" alt="Movie Poster">
  <video poster="/video-poster.png">
    <source src="/movie-trailer.mp4" type="video/mp4">
  </video>
  <iframe src="https://player.example.com/movie/123"></iframe>
</article>
"""

do {
    let mediaDoc = try parseHTML(string: mediaHTML)

    // Example 1: Find only video sources and embedded players.
    let videoURLs = try mediaDoc.urls(from: [.source, .iframe])
    print("Video Content URLs: \(videoURLs)")
    // Prints: Video Content URLs: ["/movie-trailer.mp4", "https://player.example.com/movie/123"]

    // Example 2: Get every supported URL from the document using .all.
    let allContentURLs = try mediaDoc.urls(from: .all)
    print("All URLs: \(allContentURLs)")
    // Prints: All URLs: ["/reviews/home", "/poster.jpg", "/video-poster.png", "/movie-trailer.mp4", "https://player.example.com/movie/123"]
} catch {
     print("HTML parsing failed: \(error)")
}
```

#### Example: Basic Queries and Text Access

You can also perform basic queries and access element attributes and text content directly.

```swift
import YaXHParser

let html = """
<html>
  <body>
    <div id="main" class="content">
        <p>Here is a link: <a href="/page1">Page 1</a></p>
    </div>
  </body>
</html>
"""

do {
    // Parse the HTML string.
    let doc = try parseHTML(string: html)

    // Use CSS selectors to find an element.
    if let link = try doc.select("#main a").first {
        // The .text property recursively gets all text content from a node.
        print("Link text: \(link.text)") // Prints: Link text: Page 1

        // Access attributes using getAttribute().
        if let href = link.getAttribute("href") {
            print("Link URL: \(href)") // Prints: Link URL: /page1
        }
    }
} catch {
    print("HTML parsing failed: \(error)")
}
```

### XML Parsing

Use `parseXML(string:)` for well-formed XML documents. By default, this function is **strict** and will throw an error if the XML is not perfectly well-formed. This is ideal for validation and ensuring data integrity. For more advanced control, see the "Parsing Strategies" section below.

```swift
import YaXHParser

let xml = """
<rss version="2.0">
  <channel>
    <title>My Blog</title>
    <item>
      <title>Hello World</title>
      <description>My first post!</description>
    </item>
    <item>
      <title>Second Post</title>
      <description>Another exciting update.</description>
    </item>
  </channel>
</rss>
"""

do {
    // 1. Parse the XML string using the default strict parser.
    let doc = try parseXML(string: xml)

    // 2. You can use CSS selectors on XML too.
    if let channelTitle = try doc.select("channel > title").first {
        print("Channel Title: \(channelTitle.text)") // Prints: "Channel Title: My Blog"
    }

    // 3. Iterate through all items and print their titles.
    print("\nBlog Posts:")
    let items = try doc.select("item")
    for item in items {
        if let itemTitle = item.select("title").first {
            print("- \(itemTitle.text)")
        }
    }
    // Prints:
    // Blog Posts:
    // - Hello World
    // - Second Post

} catch {
    print("XML parsing failed: \(error)")
}
```

## Advanced Topics

### Parsing Strategies (Strict vs. Lenient)

While the `parseXML` function is strict by default, you can easily switch to a lenient, error-recovering strategy by providing different `MemoryParserOptions`.

```swift
// This XML has a mismatched closing tag.
let recoverableXML = "<feed><title>Title</wrong_tag></feed>"

// Using the default strict parser would throw an error.
// _ = try parseXML(string: recoverableXML) // Throws XMLError

// By passing different options, you can enable lenient parsing.
do {
    let doc = try parseXML(string: recoverableXML, options: .lenientXML)
    // The parser recovers, and you can now work with the document.
    let title = try doc.select("title").first?.text
    print(title ?? "No title found") // Prints: "Title"
} catch {
    // This block will not be reached.
}
```

### Performance Considerations

For parsing a large number of documents, it is more efficient to create and reuse a single `MemoryParser` instance.

```swift
let parser = MemoryParser()
for xmlString in lotsOfXMLStrings {
    let doc = try parser.parse(string: xmlString)
    // ... process doc
}
```

### Concurrency

The `ParsingService` actor provides a safe way to perform parsing operations from multiple concurrent tasks. Because the underlying C library (`libxml2`) is not thread-safe, the actor serializes all parsing calls to prevent race conditions and crashes.

A common use case is to offload parsing work from the main thread in a UI application to keep it responsive. The example below shows how to parse a batch of documents concurrently in a background task.

```swift
import YaXHParser

let service = ParsingService()
let docsToParse = [
    "<doc><title>Doc 1</title></doc>",
    "<doc><title>Doc 2</title></doc>",
    "<bad-doc" // This one will fail
]

do {
    let titles = try await withThrowingTaskGroup(of: String.self, returning: [String].self) { group in
        for xml in docsToParse {
            group.addTask {
                return try await service.parseXMLAndExtract(string: xml) { doc in
                    try doc.select("title").first?.text ?? "Untitled"
                }
            }
        }

        var collected = [String]()
        for try await title in group {
            collected.append(title)
        }
        return collected
    }
    print("Successfully parsed titles: \(titles)")
} catch {
    print("A parsing task failed: \(error)")
}
// Prints: A parsing task failed: parsingError(message: "Premature end of data in tag bad-doc line 1")
```

#### Important Considerations

When using the `ParsingService`, keep the following in mind:

- **Error Handling**: Since any parsing task can fail, always use a `withThrowingTaskGroup` and be prepared to handle errors.
- **Result Order**: The order of results collected from a `TaskGroup` is not guaranteed and may differ from the order in which the tasks were added.
- **`XMLDocument` is Not `Sendable`**: The `XMLDocument` object itself is not thread-safe and must not be passed out of the actor. The `parse...AndExtract` methods are designed to handle this safely by letting you work on the document inside a closure and only returning a `Sendable` result.

### Stream Parsing (for Large Files)

`StreamParser` processes large documents piece-by-piece to minimize memory usage. You provide a custom handler to react to parsing events as they occur.

```swift
import YaXHParser

class MyEventHandler: StreamEventHandler {
    var elementCount = 0
    func handleEvent(_ event: StreamEvent) {
        if case .startElement = event {
            elementCount += 1
        }
    }
}

let handler = MyEventHandler()

do {
    let parser = try StreamParser(handler: handler)
    try parser.parseFile(at: "/path/to/large.xml")
    print("Parsed \(handler.elementCount) elements from the stream.")
} catch {
    print("Stream parsing failed: \(error)")
}
```

## Comparison to SwiftSoup

**[SwiftSoup](https://github.com/scinfu/SwiftSoup)** is a popular, pure-Swift HTML parser. `YaXHParser` has a different design philosophy and may be suitable for different tasks.

| Feature               | YaXHParser                                         | SwiftSoup                                             |
|-----------------------|------------------------------------------------------|-------------------------------------------------------|
| **Core Engine**       | A thin Swift wrapper around the system's `libxml2` C library. | A feature-rich, pure Swift implementation.            |
| **Dependencies**      | None (Foundation-free).                              | None (Pure Swift).                                    |
| **API Philosophy**    | Minimalist, focusing on querying and data extraction. | Comprehensive, supporting complex DOM manipulation.   |
| **Memory Strategy**   | Offers both in-memory and a `StreamParser` for large files. | Primarily in-memory.                                  |
| **Concurrency**       | Provides an actor for uncommon thread-safe parsing needs. | Thread-safety is managed by the user.                 |
| **Ideal Use Case**    | Fast data extraction and scraping where a minimal API is sufficient. | Projects that need to modify the DOM, or where a pure-Swift dependency is required. |

In short, choose **YaXHParser** for a lightweight tool focused on fast data extraction. Choose **[SwiftSoup](https://github.com/scinfu/SwiftSoup)** when you need a comprehensive, pure-Swift toolkit for more complex DOM manipulation.

## Local Development

This repository includes a professional setup for local development and testing on Linux, right from your Mac, using Docker. This ensures that you can test in an environment that perfectly matches the CI setup.

### Quick Testing with Docker

A Dockerfile is provided in the `.docker/` directory to test against Ubuntu.

1.  **Build the Docker Image** (only needs to be done once):
    ```sh
    # For Ubuntu (glibc)
    docker build -t ya-swift-xml-ubuntu -f .docker/Dockerfile.ubuntu .
    ```

2.  **Run Tests**:
    ```sh
    # Run tests on Ubuntu
    docker run --rm -v "$(pwd):/src" -w /src ya-swift-xml-ubuntu swift test
    ```

### Integrated Development with Devtainers

For a more integrated experience, this project is configured to be opened in a **Dev Container**. If you have a compatible editor (like Cursor or VS Code with the Dev Containers extension), you can use the command "Reopen in Container" to develop directly inside the Ubuntu Docker environment.

This gives you access to a Linux terminal and allows you to build and debug with full IDE support, all while your code remains on your local machine.

## Contributing

We welcome contributions to this project! To ensure a consistent code style, we use [SwiftFormat](https://github.com/nicklockwood/SwiftFormat).

A pre-commit hook is included in this repository to automatically format your code before you commit. To enable it, you must run a one-time setup.

### One-Time Setup

1.  **Install SwiftFormat**. The recommended way is with [Homebrew](https://brew.sh):
    ```sh
    brew install swift-format
    ```

2.  **Enable the Git Hook**. Run the following command once from the root of the repository to tell Git to use the shared hooks:
    ```sh
    git config core.hooksPath .githooks
    ```

After this setup, `swift-format` will automatically run on any staged Swift files each time you make a commit.
