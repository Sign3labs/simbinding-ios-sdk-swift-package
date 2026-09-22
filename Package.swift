// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
let version = "0.0.1001"
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
            checksum: "4307323abf2479ac3169c34e13756116066a010000660433779f848f6146d232"
        )
    ]
)
