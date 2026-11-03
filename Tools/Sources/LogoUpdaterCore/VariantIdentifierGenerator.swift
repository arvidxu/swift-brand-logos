import Foundation

/// Generates one typed identifier per artwork, with its source in the Swift name.
struct VariantIdentifierGenerator {
  func generate(_ brands: [CatalogBrand]) throws -> [String: Data] {
    let variants = brands.flatMap(\.variants).sorted { $0.id < $1.id }
    let entries = variants.map { variant -> (name: String, id: String) in
      let file = String(variant.sourceFile.dropLast(4))
      let parts = "\(variant.sourceID)-\(file)".split { !$0.isLetter && !$0.isNumber }
      var name =
        String(parts.first ?? "")
        + parts.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined()
      if name.first?.isNumber == true { name = "artwork" + name }
      return (name, variant.id)
    }
    let duplicates = Dictionary(grouping: entries, by: \.name).filter { $0.value.count > 1 }.keys.sorted()
    guard duplicates.isEmpty else {
      throw UpdateError.invalid("Artwork Swift identifier collisions: \(duplicates.joined(separator: ", "))")
    }
    let declarations = entries.flatMap { entry in
      ["  public static let `\(entry.name)` = LogoVariantID(", "    rawValue: \"\(entry.id)\")"]
    }
    var output: [String: Data] = [:]
    for start in stride(from: 0, to: declarations.count, by: 250) {
      let lines =
        ["// Generated from pinned upstream artwork. Do not edit.", "extension LogoVariantID {"]
        + declarations[start..<min(start + 250, declarations.count)] + ["}"]
      output["LogoVariantID+\(start / 250).swift"] = Data((lines.joined(separator: "\n") + "\n").utf8)
    }
    return output
  }
}
