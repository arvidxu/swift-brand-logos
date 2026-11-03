import XCTest

@testable import LogoUpdaterCore

final class SVGLogosAdapterTests: XCTestCase {
  func testAdapterKeepsVariantsWebsiteAndRecordsRejectedArtwork() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(
      at: directory.appendingPathComponent("logos"),
      withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let json = """
      [{"name":"Chrome","shortname":"chrome","url":"https://google.com/chrome/",
        "files":["chrome.svg","chrome-icon.svg","chrome-unsafe.svg"]}]
      """
    try Data(json.utf8).write(to: directory.appendingPathComponent("logos.json"))
    for filename in ["chrome.svg", "chrome-icon.svg"] {
      try Data("<svg><path fill='#ff0000'/></svg>".utf8)
        .write(to: directory.appendingPathComponent("logos/\(filename)"))
    }
    let payload = try SVGValidatorTests.imageData(type: .png).base64EncodedString()
    let embeddedIcon = Data(
      """
      <svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'>
        <image xlink:href='data:image/png;base64,\(payload)'/>
      </svg>
      """.utf8)
    try embeddedIcon.write(to: directory.appendingPathComponent("logos/chrome-icon.svg"))
    try Data("<svg><image href='https://example.com/image.png'/></svg>".utf8)
      .write(to: directory.appendingPathComponent("logos/chrome-unsafe.svg"))
    let imported = try SVGLogosAdapter().read(from: directory)
    let brand = try XCTUnwrap(imported.brands.first)
    XCTAssertEqual(brand.website, "https://google.com/chrome/")
    XCTAssertEqual(brand.artwork.count, 2)
    XCTAssertEqual(brand.artwork.min { $0.preference < $1.preference }?.filename, "chrome-icon.svg")
    XCTAssertEqual(brand.artwork.first { $0.filename == "chrome-icon.svg" }?.data, embeddedIcon)
    XCTAssertEqual(imported.skipped.count, 1)
    XCTAssertTrue(imported.skipped[0].contains("chrome-unsafe.svg"))
  }

  func testConfigurationRejectsInvalidCommitAndUnsafePaths() throws {
    let json = """
      {"sources":[{"id":"source","resourceModule":"SourceResources",
      "adapter":"svg-logos","repositoryURL":"https://example.com/logos.git",
      "commit":"main","priority":1,"license":"MIT","licensePath":"LICENSE"}],"brandMappings":{}}
      """
    let configuration = try JSONDecoder().decode(Configuration.self, from: Data(json.utf8))
    XCTAssertThrowsError(try configuration.validate())
    XCTAssertFalse(Configuration.safePath("../LICENSE"))
    XCTAssertFalse(Configuration.safePath("/LICENSE"))
  }
}
