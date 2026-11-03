import XCTest

@testable import SwiftBrandLogos

final class BrandCatalogTests: XCTestCase {
  func testBundledCatalogAndTypedIDs() throws {
    let catalog = try BrandCatalog.bundled()
    XCTAssertGreaterThan(catalog.brands.count, 1000)
    let google = try XCTUnwrap(catalog.brand(.google))
    let chrome = try XCTUnwrap(catalog.brand(.chrome))
    XCTAssertNotEqual(google.id, chrome.id)
    XCTAssertNotEqual(google.defaultVariant?.assetName, chrome.defaultVariant?.assetName)
    XCTAssertNil(catalog.brand("unknown-brand-for-test"))
    XCTAssertTrue(catalog.search("GOOGLE").contains { $0.id == "google" })
    for source in catalog.sources {
      let license = try XCTUnwrap(catalog.licenseURL(for: source.id))
      let bundle = try XCTUnwrap(SourceBundles.bundle(for: source.id))
      XCTAssertTrue(license.path.hasPrefix(bundle.bundleURL.path))
      XCTAssertEqual(license.lastPathComponent, "LICENSE.txt")
      XCTAssertNotNil(bundle.url(forResource: "source", withExtension: "json"))
      XCTAssertFalse(try Data(contentsOf: license).isEmpty)
    }
  }

  func testRejectsInvalidSchemaAndDuplicateIDs() throws {
    for json in [
      "{\"schemaVersion\":2,\"kind\":\"brand-logo-resources\",\"sources\":[],\"brands\":[]}",
      "{\"schemaVersion\":1,\"kind\":\"invalid-kind\",\"sources\":[],\"brands\":[]}",
    ] {
      XCTAssertThrowsError(try BrandCatalog(data: Data(json.utf8)))
    }
    let url = try XCTUnwrap(Bundle.module.url(forResource: "catalog", withExtension: "json"))
    var document = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
    let brands = try XCTUnwrap(document["brands"] as? [[String: Any]])
    let first = try XCTUnwrap(brands.first)
    document["brands"] = [first, first]
    XCTAssertThrowsError(try BrandCatalog(data: JSONSerialization.data(withJSONObject: document)))
  }
}
