// swift-tools-version: 5.9
import Foundation
import PackageDescription

/// Package-root-relative Vendor path (gitignored). Copy or symlink:
///   `/Users/acb/Hangyeol-xcf-build/engine/target/xcframework/HangyeolEngine.xcframework`
/// Override with env `HANGYEOL_ENGINE_XCFRAMEWORK` (absolute or package-relative).
let vendorRelativePath = "Vendor/HangyeolEngine.xcframework"

let packageRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent()

let engineLink = HangyeolEngineLink.resolve(
    packageRoot: packageRoot,
    vendorRelativePath: vendorRelativePath
)

var targets: [Target] = []

if case let .binary(relativePath) = engineLink {
    targets.append(
        .binaryTarget(
            name: "HangyeolEngine",
            path: relativePath
        )
    )
}

let cSources: [String]
let cExclude: [String]
switch engineLink {
case .stub:
    // Stub `.c` returns HG_UNSUPPORTED / NULL so Linux CI and machines
    // without Vendor still compile. Do not compile this when the XCFramework
    // is linked (duplicate hg_* symbols).
    cSources = ["hangyeol_engine.c"]
    cExclude = ["shim.c"]
case .binary, .linker:
    // Header-only clang module: declarations from hangyeol_engine.h;
    // live symbols come from the XCFramework.
    cSources = ["shim.c"]
    cExclude = ["hangyeol_engine.c"]
}

targets.append(
    .target(
        name: "CHangyeolEngine",
        path: "Sources/CHangyeolEngine",
        exclude: cExclude,
        sources: cSources,
        publicHeadersPath: "include"
    )
)

var kitDependencies: [Target.Dependency] = ["CHangyeolEngine"]
var kitSwiftSettings: [SwiftSetting] = []
var kitLinkerSettings: [LinkerSetting] = []

switch engineLink {
case .stub:
    break
case .binary:
    kitDependencies.append("HangyeolEngine")
    kitSwiftSettings.append(.define("HANGYEOL_ENGINE_LINKED"))
    kitLinkerSettings.append(contentsOf: HangyeolEngineLink.rustStaticlibSettings)
case let .linker(libraryDirectory, libraryName, isDynamic):
    kitSwiftSettings.append(.define("HANGYEOL_ENGINE_LINKED"))
    kitLinkerSettings.append(contentsOf: HangyeolEngineLink.rustStaticlibSettings)
    kitLinkerSettings.append(.unsafeFlags(
        ["-L", libraryDirectory, "-l\(libraryName)"],
        .when(platforms: [.macOS])
    ))
    if isDynamic {
        kitLinkerSettings.append(.unsafeFlags(
            ["-Xlinker", "-rpath", "-Xlinker", libraryDirectory],
            .when(platforms: [.macOS])
        ))
    }
}

targets.append(
    .target(
        name: "HangyeolKit",
        dependencies: kitDependencies,
        path: "Sources/HangyeolKit",
        swiftSettings: kitSwiftSettings,
        linkerSettings: kitLinkerSettings
    )
)

targets.append(
    .testTarget(
        name: "HangyeolKitTests",
        dependencies: ["HangyeolKit"]
    )
)

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
    targets: targets
)

// MARK: - XCFramework discovery (Package.swift evaluation only)

enum HangyeolEngineLink {
    /// In-package XCFramework → SPM `binaryTarget`.
    case binary(relativePath: String)
    /// Env path outside the package → linker flags (SPM binaryTarget must stay in-package).
    case linker(libraryDirectory: String, libraryName: String, isDynamic: Bool)
    /// No XCFramework: compile the C stub; Swift throws `notLinked`.
    case stub

    static let rustStaticlibSettings: [LinkerSetting] = [
        .linkedLibrary("iconv", .when(platforms: [.macOS])),
        .linkedLibrary("c++", .when(platforms: [.macOS])),
        .linkedFramework("CoreFoundation", .when(platforms: [.macOS])),
        .linkedFramework("Security", .when(platforms: [.macOS])),
        .linkedFramework("SystemConfiguration", .when(platforms: [.macOS])),
    ]

    static func resolve(packageRoot: URL, vendorRelativePath: String) -> HangyeolEngineLink {
        let candidates = candidatePaths(packageRoot: packageRoot, vendorRelativePath: vendorRelativePath)
        for url in candidates {
            guard isXCFramework(at: url) else { continue }
            let rootPath = packageRoot.standardizedFileURL.path
            let absPath = url.standardizedFileURL.path
            if absPath == rootPath || absPath.hasPrefix(rootPath + "/") {
                let relative = String(absPath.dropFirst(rootPath.count + 1))
                return .binary(relativePath: relative)
            }
            if let slice = findLibrarySlice(in: url) {
                return .linker(
                    libraryDirectory: slice.directory,
                    libraryName: slice.name,
                    isDynamic: slice.isDynamic
                )
            }
        }
        return .stub
    }

    static func candidatePaths(packageRoot: URL, vendorRelativePath: String) -> [URL] {
        var urls: [URL] = []
        if let env = ProcessInfo.processInfo.environment["HANGYEOL_ENGINE_XCFRAMEWORK"]?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !env.isEmpty {
            if env.hasPrefix("/") {
                urls.append(URL(fileURLWithPath: env, isDirectory: true))
            } else {
                urls.append(packageRoot.appendingPathComponent(env))
            }
        }
        urls.append(packageRoot.appendingPathComponent(vendorRelativePath))
        return urls
    }

    static func isXCFramework(at url: URL) -> Bool {
        var isDir: ObjCBool = false
        let path = url.path
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue else {
            return false
        }
        let info = url.appendingPathComponent("Info.plist").path
        if FileManager.default.fileExists(atPath: info) {
            return true
        }
        return path.hasSuffix(".xcframework")
    }

    struct Slice {
        var directory: String
        var name: String
        var isDynamic: Bool
    }

    /// Prefer macOS slices produced by `xcodebuild -create-xcframework -library`.
    static func findLibrarySlice(in xcframework: URL) -> Slice? {
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(atPath: xcframework.path) else {
            return nil
        }
        let slices = entries.filter { $0 != "Info.plist" && !$0.hasPrefix(".") }.sorted { a, b in
            macosRank(a) < macosRank(b)
        }
        for slice in slices {
            let sliceURL = xcframework.appendingPathComponent(slice)
            guard let files = try? fm.contentsOfDirectory(atPath: sliceURL.path) else { continue }
            if let archive = files.first(where: { $0.hasSuffix(".a") }) {
                return Slice(
                    directory: sliceURL.path,
                    name: libraryName(from: archive),
                    isDynamic: false
                )
            }
            if let dylib = files.first(where: { $0.hasSuffix(".dylib") }) {
                return Slice(
                    directory: sliceURL.path,
                    name: libraryName(from: dylib),
                    isDynamic: true
                )
            }
        }
        return nil
    }

    static func macosRank(_ name: String) -> Int {
        if name.hasPrefix("macos-arm64") { return 0 }
        if name.hasPrefix("macos-") { return 1 }
        return 2
    }

    /// `libhangyeol_engine.a` / `libhangyeol_engine.dylib` → `hangyeol_engine`
    static func libraryName(from fileName: String) -> String {
        var name = fileName
        if name.hasPrefix("lib") {
            name = String(name.dropFirst(3))
        }
        if name.hasSuffix(".dylib") {
            name = String(name.dropLast(6))
        } else if name.hasSuffix(".a") {
            name = String(name.dropLast(2))
        }
        return name
    }
}
