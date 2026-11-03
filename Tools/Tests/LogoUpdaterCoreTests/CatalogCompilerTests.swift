import XCTest

@testable import LogoUpdaterCore

final class CatalogCompilerTests: XCTestCase {
  func testKeepsGoogleAndChromeSeparateAndWebsiteIntact() throws {
    let source = fixture(
      "first",
      brands: [
        brand("google", "Google", website: "https://google.com/"),
        brand("chrome", "Chrome", website: "https://google.com/chrome/"),
      ])
    let catalog = try CatalogCompiler(mappings: [:]).compile([source])
    XCTAssertEqual(catalog.document.brands.map(\.id), ["chrome", "google"])
    XCTAssertEqual(catalog.document.brands[0].variants[0].sourceWebsite, "https://google.com/chrome/")
    let encoded = String(decoding: try JSONEncoder().encode(catalog.document), as: UTF8.self)
    XCTAssertFalse(encoded.contains("\"domains\""))
  }

  func testMultipleSourcesMergeDeterministicallyWithProvenance() throws {
    let first = fixture("first", priority: 20, brands: [brand("google", "Google")])
    let second = fixture("second", priority: 10, brands: [brand("google", "Google")])
    let compiler = CatalogCompiler(mappings: [:])
    let output = try compiler.compile([first, second])
    let reversed = try compiler.compile([second, first])
    XCTAssertEqual(output.document.brands.count, 1)
    XCTAssertEqual(output.document.brands[0].variants.count, 2)
    XCTAssertTrue(output.document.brands[0].defaultVariantID.hasPrefix("second/"))
    XCTAssertEqual(output.document.brands[0].defaultVariantID, reversed.document.brands[0].defaultVariantID)
    XCTAssertEqual(output.artwork, reversed.artwork)
    let files = try ResourceGenerator().files(catalog: output, sources: [first, second])
    XCTAssertEqual(files["first/Resources/LICENSE.txt"], first.license)
    XCTAssertEqual(files["second/Resources/LICENSE.txt"], second.license)
    XCTAssertFalse(files.keys.contains { !$0.contains("/") && $0.hasSuffix(".txt") })
    for source in output.document.sources {
      XCTAssertNotNil(files["\(source.id)/Resources/\(source.licenseFile)"])
      XCTAssertNotNil(files["\(source.id)/Resources/source.json"])
      XCTAssertNotNil(files["\(source.id)/Resources/Logos.xcassets/Contents.json"])
      for variant in output.document.brands.flatMap(\.variants) where variant.sourceID == source.id {
        let path = "\(source.id)/Resources/Logos.xcassets/\(variant.assetName.prefix(1).uppercased())"
        XCTAssertNotNil(files["\(path)/\(variant.assetName).imageset/logo.svg"])
      }
    }
  }

  func testAmbiguousNamesFailAndExplicitMappingCanSeparateThem() throws {
    let first = fixture("first", brands: [brand("acme", "Acme Cloud")])
    let second = fixture("second", brands: [brand("acme", "Acme Editor")])
    XCTAssertThrowsError(try CatalogCompiler(mappings: [:]).compile([first, second]))
    let separated = try CatalogCompiler(mappings: ["second": ["acme": "acme-editor"]]).compile([first, second])
    XCTAssertEqual(separated.document.brands.map(\.id), ["acme", "acme-editor"])
    let merged = try CatalogCompiler(mappings: ["second": ["acme": "acme"]]).compile([first, second])
    XCTAssertEqual(merged.document.brands.count, 1)
  }

  func testMissingMappingAndDuplicateArtworkFail() throws {
    let source = fixture("first", brands: [brand("google", "Google")])
    XCTAssertThrowsError(try CatalogCompiler(mappings: ["first": ["absent": "google"]]).compile([source]))
    XCTAssertThrowsError(try CatalogCompiler(mappings: [:]).compile([source, source]))
  }

  private func brand(_ id: String, _ name: String, website: String = "https://example.com/") -> SourceBrand {
    SourceBrand(
      id: id, name: name, website: website,
      artwork: [SourceArtwork(filename: "\(id).svg", data: Data("<svg/>".utf8), preference: 0)])
  }

  private func fixture(_ id: String, priority: Int = 10, brands: [SourceBrand]) -> LoadedSource {
    LoadedSource(
      configuration: SourceConfiguration(
        id: id, resourceModule: "\(id.capitalized)Resources", adapter: "fixture",
        repositoryURL: "https://example.com/\(id).git", commit: String(repeating: "a", count: 40),
        priority: priority, license: "MIT", licensePath: "LICENSE"), brands: brands, license: Data("MIT".utf8))
  }
}
