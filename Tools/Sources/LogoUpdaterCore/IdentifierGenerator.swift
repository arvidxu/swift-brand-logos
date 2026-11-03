import Foundation

struct IdentifierGenerator {
  func generate(_ brands: [CatalogBrand]) throws -> [String: Data] {
    let entries = brands.map { brand -> (String, String) in
      let parts = brand.id.split(whereSeparator: { !$0.isLetter && !$0.isNumber })
      var name =
        String(parts.first ?? "") + parts.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined()
      if name.first?.isNumber == true { name = "brand" + name }
      return (name, brand.id)
    }
    let counts = Dictionary(grouping: entries, by: { $0.0 }).mapValues(\.count)
    let collisions = counts.filter { $0.value > 1 }.keys.sorted()
    guard collisions.isEmpty else {
      throw UpdateError.invalid(
        "Swift identifier collisions require brandMappings: \(collisions.joined(separator: ", "))")
    }
    var declarations: [String] = []
    for (name, id) in entries {
      declarations.append("  public static let `\(name)` = BrandID(rawValue: \"\(id)\")")
    }
    var output: [String: Data] = [:]
    for start in stride(from: 0, to: declarations.count, by: 250) {
      let lines =
        ["// Generated from pinned upstream metadata. Do not edit.", "extension BrandID {"]
        + declarations[start..<min(start + 250, declarations.count)] + ["}"]
      output["BrandID+\(start / 250).swift"] = Data((lines.joined(separator: "\n") + "\n").utf8)
    }
    return output
  }
}
