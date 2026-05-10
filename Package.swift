// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "spacemap",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "spacemap",
            path: "Sources/spacemap",
            exclude: ["Info.plist"]
        )
    ]
)
