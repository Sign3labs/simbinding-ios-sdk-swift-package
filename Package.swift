// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
let version = "0.0.1000"
let package = Package(
    name: "SimBinding",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "SimBinding",
            targets: ["SimBinding"]),
    ],
    targets: [
        .binaryTarget(
            name: "SimBinding",
            url: "https://cdn.sign3.in/mobile-sdk/ios/test/simbinding/v\(version)/SimBinding.xcframework.zip",
            checksum: "167204a507ccf0443255e34ffe0dcdd776ccc446e31b4758270a4c464138d642"
        )
    ]
)
