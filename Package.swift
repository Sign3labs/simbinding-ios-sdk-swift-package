// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
let version = "0.0.1002"
let authIoVersion = "3.0.2"
let package = Package(
    name: "SimBinding",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "SimBinding",
            targets: ["SimBinding", "AuthIoSDK"]),
    ],
    targets: [
        .binaryTarget(
            name: "SimBinding",
            url: "https://cdn.sign3.in/mobile-sdk/ios/test/simbinding/v\(version)/SimBinding.xcframework.zip",
            checksum: "96afc92c27f4c0aabf5cbaac0e3ab1084a955d78f942d8b4f366be652b89190e"
        ),
        // Authentication engine SimBinding links against. Shipped inside the SimBinding product so
        // integrators add one package and Xcode embeds both frameworks.
        .binaryTarget(
            name: "AuthIoSDK",
            url: "https://cdn.sign3.in/mobile-sdk/ios/test/authio/v\(authIoVersion)/AuthIoSDK-\(authIoVersion).xcframework.zip",
            checksum: "5cce8ccd03c4050b1cad72c9855edceb29fbe627f3fe6a211961cc1a8e6c03c4"
        )
    ]
)
