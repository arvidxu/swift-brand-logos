import XCTest

@testable import SwiftBrandLogos

final class LogoVariantTests: XCTestCase {
  func testEveryBundledArtworkCanBeSelectedExplicitly() throws {
    let catalog = try BrandCatalog.bundled()
    for brand in catalog.brands {
      for artwork in brand.variants {
        let variantID = LogoVariantID(rawValue: artwork.id)
        let selected = BrandLogo(id: brand.id, variant: variantID).resolveVariant(in: brand)
        XCTAssertEqual(selected?.id, artwork.id)
        XCTAssertEqual(selected?.assetName, artwork.assetName)
      }
    }
  }

  func testGmailVersionsResolveToDifferentArtwork() throws {
    let brand = try XCTUnwrap(BrandCatalog.bundled().brand(.googleGmail))
    let unversioned = try XCTUnwrap(brand.variant(.svgLogosGoogleGmail))
    let dated = try XCTUnwrap(brand.variant(.svgLogosGoogleGmail2020))
    XCTAssertEqual(unversioned.sourceFile, "google-gmail.svg")
    XCTAssertEqual(dated.sourceFile, "google-gmail-2020.svg")
    XCTAssertNotEqual(unversioned.assetName, dated.assetName)
    XCTAssertNotEqual(unversioned.sha256, dated.sha256)
    XCTAssertEqual(
      BrandLogo(.googleGmail, variant: .svgLogosGoogleGmail2020)
        .resolveVariant(in: brand)?.id, dated.id)
    XCTAssertEqual(BrandLogo(.googleGmail).resolveVariant(in: brand)?.id, brand.defaultVariantID)
  }

  func testUnavailableArtworkReturnsNil() throws {
    let brand = try XCTUnwrap(BrandCatalog.bundled().brand(.googleGmail))
    XCTAssertNil(BrandLogo(id: "unknown-brand").resolveVariant(in: nil))
    XCTAssertNil(BrandLogo(.googleGmail, variant: "unknown/variant").resolveVariant(in: brand))
    XCTAssertNil(BrandLogo(.googleGmail, variant: .svgLogosChrome).resolveVariant(in: brand))
    XCTAssertNil(BrandLogo(.googleGmail, source: "unknown-source").resolveVariant(in: brand))
  }
}
