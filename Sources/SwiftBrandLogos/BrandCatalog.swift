import Foundation

/// Bundled resource metadata. Loading and searching never makes network requests.
public struct BrandCatalog: Sendable {
  public let brands: [BrandInfo]
  public let sources: [LogoSource]
  private let byID: [String: BrandInfo]

  private struct Document: Decodable {
    let schemaVersion: Int
    let kind: String
    let sources: [LogoSource]
    let brands: [BrandInfo]
  }

  public enum CatalogError: Error {
    case missingResource
    case invalidCatalog
  }

  private static let cached: Result<BrandCatalog, Error> = Result {
    guard let url = Bundle.module.url(forResource: "catalog", withExtension: "json") else {
      throw CatalogError.missingResource
    }
    return try BrandCatalog(data: Data(contentsOf: url))
  }

  public static func bundled() throws -> BrandCatalog { try cached.get() }

  init(data: Data) throws {
    let document = try JSONDecoder().decode(Document.self, from: data)
    guard document.schemaVersion == 1, document.kind == "brand-logo-resources",
      Set(document.brands.map(\.id)).count == document.brands.count,
      Set(document.sources.map(\.id)).count == document.sources.count
    else { throw CatalogError.invalidCatalog }
    let sourceIDs = Set(document.sources.map(\.id))
    for brand in document.brands {
      guard brand.defaultVariant != nil,
        Set(brand.variants.map(\.id)).count == brand.variants.count,
        brand.variants.allSatisfy({ sourceIDs.contains($0.sourceID) })
      else { throw CatalogError.invalidCatalog }
    }
    brands = document.brands
    sources = document.sources
    byID = Dictionary(uniqueKeysWithValues: brands.map { ($0.id, $0) })
  }

  public func brand(_ id: BrandID) -> BrandInfo? { byID[id.rawValue] }

  /// Searches brand names and IDs without case sensitivity.
  public func search(_ query: String) -> [BrandInfo] {
    let value = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty else { return brands }
    return brands.filter {
      $0.name.localizedCaseInsensitiveContains(value) || $0.id.localizedCaseInsensitiveContains(value)
    }
  }

  public func licenseURL(for sourceID: String) -> URL? {
    guard let source = sources.first(where: { $0.id == sourceID }) else { return nil }
    let path = source.licenseFile as NSString
    return SourceBundles.bundle(for: sourceID)?.url(
      forResource: path.lastPathComponent, withExtension: nil, subdirectory: path.deletingLastPathComponent)
  }
}
