import Foundation

struct SVGLogosAdapter: SourceAdapter {
  private struct Entry: Decodable {
    let name: String
    let shortname: String
    let url: String
    let files: [String]
  }

  func read(from checkout: URL) throws -> SourceImport {
    let data = try Data(contentsOf: checkout.appendingPathComponent("logos.json"))
    let entries = try JSONDecoder().decode([Entry].self, from: data)
    guard Set(entries.map(\.shortname)).count == entries.count else {
      throw UpdateError.invalid("Duplicate upstream brand IDs.")
    }
    var skipped: [String] = []
    let brands = try entries.compactMap { entry -> SourceBrand? in
      guard Configuration.validID(entry.shortname.lowercased()), !entry.name.isEmpty else {
        throw UpdateError.invalid("Invalid upstream identity: \(entry.shortname)")
      }
      let preferred = ["\(entry.shortname)-icon.svg", "\(entry.shortname).svg"]
      let artwork = try entry.files.enumerated().compactMap { index, filename -> SourceArtwork? in
        guard URL(fileURLWithPath: filename).lastPathComponent == filename,
          filename.hasSuffix(".svg"), !filename.contains("..")
        else { throw UpdateError.invalid("Invalid upstream SVG path: \(filename)") }
        let svg = try Data(contentsOf: checkout.appendingPathComponent("logos/\(filename)"))
        do { try SVGValidator.validate(svg, name: filename) } catch {
          skipped.append("\(entry.shortname)/\(filename): \(error)")
          return nil
        }
        return SourceArtwork(filename: filename, data: svg, preference: preferred.firstIndex(of: filename) ?? index + 2)
      }
      guard !artwork.isEmpty else {
        skipped.append("\(entry.shortname): no self-contained SVG variant")
        return nil
      }
      return SourceBrand(id: entry.shortname, name: entry.name, website: entry.url, artwork: artwork)
    }
    return SourceImport(brands: brands, skipped: skipped.sorted())
  }
}
