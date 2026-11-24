// swift-tools-version: 5.9
// Local build of Sign3Intelligence from the feature-simbinding-module branch
// (has UserEventType.AUTH and IntelligenceResponse.snaRequestId).
// Swap back to the remote package once Sign3 publishes a release with SIM binding.
import PackageDescription

let package = Package(
    name: "Sign3Intelligence",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "Sign3Intelligence", targets: ["Sign3Intelligence"])
    ],
    targets: [
        .binaryTarget(name: "Sign3Intelligence", path: "Sign3Intelligence.xcframework")
    ]
)
