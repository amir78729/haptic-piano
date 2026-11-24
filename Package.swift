// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HapticPiano",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "HapticPiano", targets: ["HapticPiano"]),
        .executable(name: "HapticPianoChecks", targets: ["HapticPianoChecks"])
    ],
    targets: [
        .target(name: "HapticPianoCore", path: "Sources/HapticPiano/Domain"),
        .executableTarget(
            name: "HapticPiano",
            dependencies: ["HapticPianoCore"],
            exclude: ["Domain"]
        ),
        .executableTarget(
            name: "HapticPianoChecks",
            dependencies: ["HapticPianoCore"],
            path: "Verification",
            sources: ["HapticPianoChecks.swift"]
        )
    ]
)
