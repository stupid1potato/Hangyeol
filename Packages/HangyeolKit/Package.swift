// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HangyeolKit",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "HangyeolKit",
            targets: ["HangyeolKit"]
        ),
    ],
    targets: [
        // C ABI draft. Header-only would not compile as an SPM clang target,
        // so a stub .c that only returns error statuses is included.
        // Do not link this product from Apps/Hangyeol (MockEngine stays live).
        .target(
            name: "CHangyeolEngine",
            path: "Sources/CHangyeolEngine",
            publicHeadersPath: "include"
        ),
        .target(
            name: "HangyeolKit",
            dependencies: ["CHangyeolEngine"],
            path: "Sources/HangyeolKit"
        ),
    ]
)
