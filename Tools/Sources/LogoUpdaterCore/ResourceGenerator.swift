import Foundation

struct ResourceGenerator {
  func files(catalog: CompiledCatalog, sources: [LoadedSource]) throws -> [String: Data] {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    var output: [String: Data] = [:]
    let info: [String: Any] = ["author": "xcode", "version": 1]
    let sourceByAsset = Dictionary(
      uniqueKeysWithValues:
        catalog.document.brands.flatMap(\.variants).map { ($0.assetName, $0.sourceID) })
    for (asset, data) in catalog.artwork {
      guard let source = sourceByAsset[asset] else { throw UpdateError.invalid("Missing source for \(asset)") }
      let folder = "\(source)/Resources/Logos.xcassets/\(asset.prefix(1).uppercased())/\(asset).imageset"
      output["\(folder)/logo.svg"] = data
      output["\(folder)/Contents.json"] = try json([
        "info": info,
        "images": [["idiom": "universal", "filename": "logo.svg"]],
        "properties": ["preserves-vector-representation": true, "template-rendering-intent": "original"],
      ])
    }
    for source in sources {
      let prefix = "\(source.configuration.id)/Resources"
      output["\(prefix)/Logos.xcassets/Contents.json"] = try json(["info": info])
      output["\(prefix)/LICENSE.txt"] = source.license
      guard let metadata = catalog.document.sources.first(where: { $0.id == source.configuration.id }) else {
        throw UpdateError.invalid("Missing source provenance")
      }
      output["\(prefix)/source.json"] = try encoder.encode(metadata)
    }
    return output
  }

  private func json(_ value: [String: Any]) throws -> Data {
    try JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
  }
}
