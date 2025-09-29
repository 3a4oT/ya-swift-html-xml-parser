// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ya-swift-html-xml-parser",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11),
        .visionOS(.v2)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ya-swift-html-xml-parser",
            targets: ["ya-swift-html-xml-parser"]
        )
    ],
    dependencies: [],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "ya-swift-html-xml-parser",
            dependencies: ["CLibXML2", "LibXMLTrampolines"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("NonescapableTypes"),
                .enableUpcomingFeature("InternalImportsByDefault")
            ]
        ),
        .target(
            name: "LibXMLTrampolines",
            dependencies: ["CLibXML2"],
            path: "Sources/LibXMLTrampolines",
            publicHeadersPath: "include"

        ),
        .systemLibrary(
            name: "CLibXML2",
            pkgConfig: "libxml-2.0",
            providers: [
                .brew(["libxml2"]),
                .apt(["libxml2-dev"])
            ]
        ),
        .testTarget(
            name: "ya-swift-html-xml-parserTests",
            dependencies: [
                "ya-swift-html-xml-parser"
            ]
        )
    ]
)
