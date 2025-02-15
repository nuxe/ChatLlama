// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "ChatLlama",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "ChatLlama",
            targets: ["ChatLlama"]),
    ],
    dependencies: [
        .package(url: "https://github.com/MessageKit/MessageKit.git", from: "4.0.0"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "ChatLlama",
            dependencies: [
                "MessageKit",
                "Alamofire"
            ]),
        .testTarget(
            name: "ChatLlamaTests",
            dependencies: ["ChatLlama"]),
    ]
) 