import XCTest

@testable import LogoUpdaterCore

final class ResourceTests: XCTestCase {
  func testTypedIdentifierCollisionsFailInsteadOfDroppingABrand() {
    let brands = ["foo-bar", "foo_bar"].map {
      CatalogBrand(id: $0, name: $0, defaultVariantID: "fixture", variants: [])
    }
    XCTAssertThrowsError(try IdentifierGenerator().generate(brands))
  }

  func testVerificationDetectsMissingChangedAndExtraFiles() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    let writer = ResourceWriter()
    let expected = ["nested/icon.svg": Data("original".utf8)]
    try writer.write(expected, at: directory)
    try writer.verify(expected, at: directory)
    let icon = directory.appendingPathComponent("nested/icon.svg")
    try Data("changed".utf8).write(to: icon)
    XCTAssertThrowsError(try writer.verify(expected, at: directory))
    try FileManager.default.removeItem(at: icon)
    XCTAssertThrowsError(try writer.verify(expected, at: directory))
    try writer.write(expected, at: directory)
    try Data().write(to: directory.appendingPathComponent("extra"))
    XCTAssertThrowsError(try writer.verify(expected, at: directory))
    try writer.write(expected, at: directory)
    try writer.verify(expected, at: directory)
  }

}
