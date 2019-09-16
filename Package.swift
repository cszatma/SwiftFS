// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "SwiftFS",
    products: [
        .library(
            name: "SwiftFS",
            targets: ["SwiftFS"]
        ),
        .library(
            name: "MockFS",
            targets: ["MockFS"]
        ),
    ],
    dependencies: [
        // devDependencies
        .package(url: "https://github.com/Quick/Quick.git", from: "2.1.0"), // dev
        .package(url: "https://github.com/Quick/Nimble.git", from: "8.0.0"), // dev
    ],
    targets: [
        .target(
            name: "SwiftFS",
            dependencies: []
        ),
        .testTarget(name: "SwiftFSTests", dependencies: ["SwiftFS", "MockFS", "Quick", "Nimble"]), // dev
        .target(
            name: "MockFS",
            dependencies: ["SwiftFS"]
        ),
        .testTarget(name: "MockFSTests", dependencies: ["MockFS", "Quick", "Nimble"]) // dev
    ],
    swiftLanguageVersions: [.v5]
)
