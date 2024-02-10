// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MenuItemView",
		platforms: [.macOS(.v10_13)],
    products: [
        .library(
            name: "MenuItemView",
            targets: ["MenuItemView"]),
    ],
    targets: [
        .target(
            name: "MenuItemView"),
    ]
)
