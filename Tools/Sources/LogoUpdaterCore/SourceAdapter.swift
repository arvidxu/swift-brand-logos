import Foundation

/// Adapters know upstream formats; they do not write package resources or choose global brand IDs.
protocol SourceAdapter {
  func read(from checkout: URL) throws -> SourceImport
}

struct SourceImport {
  let brands: [SourceBrand]
  let skipped: [String]
}

struct SourceBrand {
  let id: String
  let name: String
  let website: String
  let artwork: [SourceArtwork]
}

struct SourceArtwork {
  let filename: String
  let data: Data
  let preference: Int
}

enum AdapterRegistry {
  static func adapter(named name: String) throws -> any SourceAdapter {
    switch name {
    case "svg-logos": return SVGLogosAdapter()
    default: throw UpdateError.invalid("Unknown source adapter: \(name)")
    }
  }
}
