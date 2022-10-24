// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "YYRefresh",
    products: [
        .library(name: "YYRefresh",targets: ["YYRefresh"]),
    ],
    dependencies: [.package(url: "https://github.com/airbnb/lottie-ios.git", branch: "master")],
    targets: [
        .target(
            name: "YYRefresh",
            dependencies: ["Lottie"]),
    ]
)
