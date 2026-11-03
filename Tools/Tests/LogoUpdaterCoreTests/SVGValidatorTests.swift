import ImageIO
import UniformTypeIdentifiers
import XCTest

@testable import LogoUpdaterCore

final class SVGValidatorTests: XCTestCase {
  func testAcceptsSVGNamespacesAndInternalReferences() throws {
    for svg in [
      "<svg><path fill='#ff0000'/><use href='#icon'/></svg>",
      "<svg xmlns='http://www.w3.org/2000/svg'><use href='#icon'/></svg>",
      "<s:svg xmlns:s='http://www.w3.org/2000/svg'><s:path/></s:svg>",
    ] {
      try validate(svg)
    }
  }

  func testAcceptsRealEmbeddedRasterImages() throws {
    for (mime, type) in [("image/png", UTType.png), ("image/jpeg", .jpeg), ("image/gif", .gif)] {
      let payload = try Self.imageData(type: type).base64EncodedString()
      try validate("<svg><image href='data:\(mime);base64,\(payload)'/></svg>")
      try validate(
        """
        <svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'>
          <image xlink:href='data:\(mime);base64, \(payload) '/>
        </svg>
        """)
    }
  }

  func testRejectsMalformedOrMislabeledEmbeddedImages() throws {
    let png = try Self.imageData(type: .png).base64EncodedString()
    let encodedSVG = Data("<svg><script/></svg>".utf8).base64EncodedString()
    for uri in [
      "data:image/png;base64", "data:image/png;base64,", "data:image/png;base64,%%%",
      "data:image/png;base64,iVBORw0KGgo=", "data:image/jpeg;base64,\(png)",
      "data:image/svg+xml;base64,\(encodedSVG)", "data:image/png;base64,\(encodedSVG)",
      "data:text/html;base64,\(encodedSVG)", "data:image/png,\(png)",
    ] {
      XCTAssertThrowsError(try validate("<svg><image href='\(uri)'/></svg>"), uri)
    }
  }

  func testRejectsMalformedStructureActiveContentAndExternalReferences() throws {
    for svg in [
      "<html/>", "<svg>", "<svg xmlns='https://example.com/other'/>", "<SVG/>",
      "<svg><script/></svg>", "<svg><foreignObject/></svg>", "<svg onload='run()'/>",
      "<svg><use href='https://example.com/a'/></svg>",
      "<svg><image href='file:///tmp/a.png'/></svg>", "<svg><image href='a.png'/></svg>",
      "<svg><image href='javascript:run()'/></svg>",
      "<svg><use href='data:image/png;base64,iVBORw0KGgo='/></svg>",
    ] {
      XCTAssertThrowsError(try validate(svg), svg)
    }
  }

  func testFailureIncludesFilenameAndReason() {
    XCTAssertThrowsError(try validate("<svg><image href='data:image/png;base64,%%%'/></svg>")) { error in
      XCTAssertTrue(String(describing: error).contains("fixture.svg: image href: Invalid Base64 image data."))
    }
  }

  private func validate(_ svg: String) throws {
    try SVGValidator.validate(Data(svg.utf8), name: "fixture.svg")
  }

  static func imageData(type: UTType) throws -> Data {
    let context = try XCTUnwrap(
      CGContext(
        data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue))
    context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
    let image = try XCTUnwrap(context.makeImage())
    let data = NSMutableData()
    let destination = try XCTUnwrap(CGImageDestinationCreateWithData(data, type.identifier as CFString, 1, nil))
    CGImageDestinationAddImage(destination, image, nil)
    XCTAssertTrue(CGImageDestinationFinalize(destination))
    return data as Data
  }
}
