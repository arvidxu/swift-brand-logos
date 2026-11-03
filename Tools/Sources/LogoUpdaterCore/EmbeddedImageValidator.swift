import Foundation
import ImageIO
import UniformTypeIdentifiers

enum EmbeddedImageValidator {
  private static let supportedTypes: [String: UTType] = [
    "image/png": .png,
    "image/jpeg": .jpeg,
    "image/gif": .gif,
  ]

  static func validate(_ reference: String) throws {
    guard let comma = reference.firstIndex(of: ",") else {
      throw UpdateError.invalid("Missing data URI separator.")
    }
    let header = reference[..<comma].lowercased().split(separator: ";", omittingEmptySubsequences: false)
    guard header.count == 2, header[0].hasPrefix("data:"), header[1] == "base64",
      let expectedType = supportedTypes[String(header[0].dropFirst(5))]
    else {
      throw UpdateError.invalid("Expected a Base64 PNG, JPEG, or GIF image.")
    }
    // XML attributes may contain whitespace around wrapped Base64 lines.
    let payload = reference[reference.index(after: comma)...].filter { !$0.isWhitespace }
    guard let data = Data(base64Encoded: payload), !data.isEmpty else {
      throw UpdateError.invalid("Invalid Base64 image data.")
    }
    guard let source = CGImageSourceCreateWithData(data as CFData, nil),
      let actualType = CGImageSourceGetType(source), actualType as String == expectedType.identifier
    else {
      throw UpdateError.invalid("Image data does not match its MIME type.")
    }
    let count = CGImageSourceGetCount(source)
    guard count > 0, CGImageSourceGetStatus(source) == .statusComplete else {
      throw UpdateError.invalid("Incomplete embedded image.")
    }
    for index in 0..<count {
      guard
        CGImageSourceCreateImageAtIndex(source, index, [kCGImageSourceShouldCacheImmediately: true] as CFDictionary)
          != nil,
        CGImageSourceGetStatusAtIndex(source, index) == .statusComplete
      else {
        throw UpdateError.invalid("Cannot decode embedded image.")
      }
    }
  }
}
