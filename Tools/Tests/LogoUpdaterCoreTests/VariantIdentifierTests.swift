import XCTest

@testable import LogoUpdaterCore

final class VariantIdentifierTests: XCTestCase {
  func testLargeCatalogSplitsFilesWithoutLosingArtwork() throws {
    let variants = (0..<300).map { variant("source", "version-\($0)") }
    let brand = CatalogBrand(id: "example", name: "Example", defaultVariantID: variants[0].id, variants: variants)
    let files = try VariantIdentifierGenerator().generate([brand])
    XCTAssertEqual(files.count, 3)
    for file in files.values {
      XCTAssertLessThan(String(decoding: file, as: UTF8.self).split(separator: "\n").count, 400)
    }
    let combined = files.values.map { String(decoding: $0, as: UTF8.self) }.joined()
    XCTAssertEqual(combined.components(separatedBy: "public static let").count - 1, variants.count)
    for variant in variants { XCTAssertTrue(combined.contains("\"\(variant.id)\"")) }
  }

  func testGeneratesEveryVersionAndSeparatesSources() throws {
    let variants = [
      variant("svg-logos", "google-gmail"), variant("svg-logos", "google-gmail-2020"),
      variant("other", "google-gmail-2020"),
    ]
    let brand = CatalogBrand(id: "google-gmail", name: "Gmail", defaultVariantID: variants[0].id, variants: variants)
    let files = try VariantIdentifierGenerator().generate([brand])
    let text = files.values.map { String(decoding: $0, as: UTF8.self) }.joined()
    for name in ["svgLogosGoogleGmail", "svgLogosGoogleGmail2020", "otherGoogleGmail2020"] {
      XCTAssertTrue(text.contains("`\(name)`"))
    }
    for variant in variants { XCTAssertTrue(text.contains(variant.id)) }
  }

  func testRejectsNamesThatWouldGenerateTheSameSwiftIdentifier() {
    let variants = [variant("svg-logos", "foo-bar"), variant("svg-logos", "foo_bar")]
    let brand = CatalogBrand(id: "foo", name: "Foo", defaultVariantID: variants[0].id, variants: variants)
    XCTAssertThrowsError(try VariantIdentifierGenerator().generate([brand]))
  }

  private func variant(_ source: String, _ file: String) -> CatalogVariant {
    CatalogVariant(
      id: "\(source)/google-gmail/\(file)", sourceID: source, sourceBrandID: "google-gmail",
      sourceFile: "\(file).svg", sourceWebsite: "https://gmail.com", assetName: file, sha256: "fixture")
  }
}
