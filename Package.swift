// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "YaSwiftXML",
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
            name: "YaSwiftXML",
            targets: ["YaSwiftXML"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/swiftlang/swift-testing.git", from: "0.13.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "YaSwiftXML",
            dependencies: ["CLibXML2"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
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
            name: "YaSwiftXMLTests",
            dependencies: [
                "YaSwiftXML",
                .product(name: "Testing", package: "swift-testing")
            ]
        ),
    ]
)
