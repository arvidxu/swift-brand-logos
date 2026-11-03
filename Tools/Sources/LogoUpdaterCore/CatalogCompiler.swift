import CryptoKit
import Foundation

/// Cross-source identity decisions live here, never in adapters or runtime UI code.
struct CatalogCompiler {
  let mappings: [String: [String: String]]

  private struct Candidate {
    let brand: SourceBrand
    let artwork: SourceArtwork
    let source: SourceConfiguration
    let explicit: Bool
  }

  func compile(_ sources: [LoadedSource]) throws -> CompiledCatalog {
    var grouped: [String: [Candidate]] = [:]
    for source in sources {
      let mapping = mappings[source.configuration.id] ?? [:]
      let known = Set(source.brands.map(\.id))
      guard Set(mapping.keys).isSubset(of: known) else {
        throw UpdateError.invalid("Mapping references a missing upstream brand: \(source.configuration.id)")
      }
      for brand in source.brands {
        let id = mapping[brand.id] ?? brand.id.lowercased()
        for artwork in brand.artwork {
          grouped[id, default: []].append(
            Candidate(brand: brand, artwork: artwork, source: source.configuration, explicit: mapping[brand.id] != nil))
        }
      }
    }
    var brands: [CatalogBrand] = []
    var assets: [String: Data] = [:]
    for id in grouped.keys.sorted() {
      let candidates = grouped[id]!.sorted(by: preferred)
      let implicitNames = Set(candidates.filter { !$0.explicit }.map { $0.brand.name.lowercased() })
      guard implicitNames.count <= 1 else {
        throw UpdateError.invalid("Conflicting brand ID '\(id)'. Add explicit source brandMappings before merging.")
      }
      let variants = try candidates.map { candidate -> CatalogVariant in
        let fileID = String(candidate.artwork.filename.dropLast(4))
        let variantID = "\(candidate.source.id)/\(candidate.brand.id)/\(fileID)"
        let suffix = Self.sha256(Data(variantID.utf8)).prefix(16)
        let asset = "\(id)--\(suffix)"
        guard assets[asset] == nil else { throw UpdateError.invalid("Duplicate resource identity: \(asset)") }
        assets[asset] = candidate.artwork.data
        return CatalogVariant(
          id: variantID,
          sourceID: candidate.source.id, sourceBrandID: candidate.brand.id,
          sourceFile: candidate.artwork.filename, sourceWebsite: candidate.brand.website,
          assetName: asset, sha256: Self.sha256(candidate.artwork.data))
      }
      guard let first = variants.first else { continue }
      brands.append(
        CatalogBrand(id: id, name: candidates[0].brand.name, defaultVariantID: first.id, variants: variants))
    }
    guard !brands.isEmpty else { throw UpdateError.invalid("No logos generated.") }
    let provenance = try sources.map {
      guard let commit = $0.configuration.commit else {
        throw UpdateError.invalid("Missing commit for \($0.configuration.id)")
      }
      return CatalogSource(
        id: $0.configuration.id, repositoryURL: $0.configuration.repositoryURL,
        commit: commit, license: $0.configuration.license,
        licenseFile: "LICENSE.txt")
    }.sorted { $0.id < $1.id }
    return CompiledCatalog(document: CatalogDocument(sources: provenance, brands: brands), artwork: assets)
  }

  private func preferred(_ left: Candidate, _ right: Candidate) -> Bool {
    if left.source.priority != right.source.priority { return left.source.priority < right.source.priority }
    if left.source.id != right.source.id { return left.source.id < right.source.id }
    if left.artwork.preference != right.artwork.preference { return left.artwork.preference < right.artwork.preference }
    return "\(left.brand.id)/\(left.artwork.filename)" < "\(right.brand.id)/\(right.artwork.filename)"
  }

  static func sha256(_ data: Data) -> String {
    SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
  }
}
