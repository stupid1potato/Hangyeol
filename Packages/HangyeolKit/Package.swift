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
        // C ABI synced from engine/include/hangyeol_engine.h (source of truth).
        // Stub .c returns HG_UNSUPPORTED / NULL so the clang target compiles.
        // Do not SPM-link engine/ and do not link this product from Apps/Hangyeol
        // (MockEngine stays live; RealEngine waits for XCFramework).
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
