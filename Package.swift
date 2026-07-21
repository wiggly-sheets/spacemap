// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "spacemap",
    defaultLocalization: "en",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "spacemap",
            path: "Sources/spacemap",
            exclude: ["Info.plist"],
            resources: [
                .process("AppIcon.icns"),
                .process("spacemap.icns"),
                .process("Assets.xcassets"),
                .process("Resources"),
            ],
            linkerSettings: [
                .linkedFramework("CoreGraphics"),
                .linkedFramework("ApplicationServices"),
                .linkedLibrary("c++")
            ]
        ),
        .testTarget(
            name: "spacemapTests",
            dependencies: ["spacemap"],
            path: "Tests/spacemapTests"
        )
    ]
)