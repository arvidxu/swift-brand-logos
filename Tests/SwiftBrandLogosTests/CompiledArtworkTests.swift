#if canImport(AppKit)
  import AppKit
  import XCTest
  @testable import SwiftBrandLogos

  final class CompiledArtworkTests: XCTestCase {
    func testEveryCompiledVariantLoadsAsAnImage() throws {
      let catalog = try BrandCatalog.bundled()
      let bundles = try catalog.sources.map { try XCTUnwrap(SourceBundles.bundle(for: $0.id)) }
      guard bundles.allSatisfy({ $0.url(forResource: "Assets", withExtension: "car") != nil }) else {
        throw XCTSkip("Run with xcodebuild test to compile asset catalogs; swift test only copies them.")
      }
      for brand in catalog.brands {
        for variant in brand.variants {
          let bundle = try XCTUnwrap(SourceBundles.bundle(for: variant.sourceID))
          let image = try XCTUnwrap(bundle.image(forResource: NSImage.Name(variant.assetName)), variant.id)
          XCTAssertTrue(image.isValid, variant.id)
          XCTAssertGreaterThan(image.size.width, 0, variant.id)
          XCTAssertGreaterThan(image.size.height, 0, variant.id)
        }
      }
    }
  }
#endif
