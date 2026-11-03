// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "SwiftBrandLogos",
  platforms: [.iOS(.v15), .macOS(.v12), .watchOS(.v8), .tvOS(.v15), .visionOS(.v1)],
  products: [.library(name: "SwiftBrandLogos", targets: ["SwiftBrandLogos"])],
  targets: [
    .target(
      name: "SwiftBrandLogos",
      dependencies: ["SVGLogosResources"],
      resources: [.process("Resources/catalog.json")]),
    .testTarget(name: "SwiftBrandLogosTests", dependencies: ["SwiftBrandLogos"]),
    .target(
      name: "SVGLogosResources",
      path: "Sources/Upstreams/svg-logos",
      resources: [.process("Resources")]),
  ]
)
