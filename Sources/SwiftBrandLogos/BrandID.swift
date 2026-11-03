import Foundation

/// A stable brand identifier in the catalog.
public struct BrandID: RawRepresentable, Codable, Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String

  public init(rawValue: String) { self.rawValue = rawValue }
  public init(stringLiteral value: String) { self.init(rawValue: value) }
}
