import Foundation

public struct BrandInfo: Decodable, Identifiable, Hashable, Sendable {
  public let id: String
  public let name: String
  public let defaultVariantID: String
  public let variants: [LogoVariant]

  public var defaultVariant: LogoVariant? { variants.first { $0.id == defaultVariantID } }

  /// Returns the requested artwork belonging to this brand, or nil if it is unavailable.
  public func variant(_ id: LogoVariantID) -> LogoVariant? {
    variants.first { $0.id == id.rawValue }
  }
}

public struct LogoVariant: Decodable, Identifiable, Hashable, Sendable {
  public let id: String
  public let sourceID: String
  public let sourceBrandID: String
  public let sourceFile: String
  /// Product website recorded by the upstream source.
  public let sourceWebsite: String
  public let assetName: String
  public let sha256: String
}

public struct LogoSource: Decodable, Identifiable, Sendable {
  public let id: String
  public let repositoryURL: String
  public let commit: String
  public let license: String
  public let licenseFile: String
}
