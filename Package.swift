// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BarredAwake",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "BarredAwake",
            path: "Sources/BarredAwake"
        )
    ]
)
