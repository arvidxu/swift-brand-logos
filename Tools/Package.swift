// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "BrandLogoTools",
  platforms: [.macOS(.v13)],
  products: [.executable(name: "update-brand-logos", targets: ["LogoUpdater"])],
  targets: [
    .target(name: "LogoUpdaterCore"),
    .executableTarget(name: "LogoUpdater", dependencies: ["LogoUpdaterCore"]),
    .testTarget(name: "LogoUpdaterCoreTests", dependencies: ["LogoUpdaterCore"]),
  ]
)
