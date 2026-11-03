import Foundation

public struct Updater {
  public init() {}

  public func run(root: URL, check: Bool, sourceOverrides: [String: URL] = [:]) throws {
    var configuration = try Configuration.load(root: root)
    guard Set(sourceOverrides.keys).isSubset(of: Set(configuration.sources.map(\.id))) else {
      throw UpdateError.invalid("Unknown source override.")
    }
    let store = RepositoryStore(offline: check)
    if !check {
      configuration.sources = try configuration.sources.map { source in
        try store.resolveCommit(for: source, at: sourceOverrides[source.id])
      }
    }
    var skipped: [String: [String]] = [:]
    let sources = try configuration.sources.map { source in
      let checkout: URL
      if let override = sourceOverrides[source.id] {
        try store.validate(override, source: source)
        checkout = override
      } else {
        checkout = try store.checkout(source)
      }
      let adapter = try AdapterRegistry.adapter(named: source.adapter)
      let imported = try adapter.read(from: checkout)
      skipped[source.id] = imported.skipped
      return LoadedSource(
        configuration: source, brands: imported.brands,
        license: try Data(contentsOf: checkout.appendingPathComponent(source.licensePath)))
    }
    let compiled = try CatalogCompiler(mappings: configuration.brandMappings).compile(sources)
    var identifiers = try IdentifierGenerator().generate(compiled.document.brands)
    let variantIdentifiers = try VariantIdentifierGenerator().generate(compiled.document.brands)
    identifiers.merge(variantIdentifiers) { _, new in new }
    let moduleGenerator = SourceModuleGenerator()
    identifiers["SourceBundles.swift"] = moduleGenerator.registry(configuration.sources)
    var upstreamFiles = try ResourceGenerator().files(catalog: compiled, sources: sources)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    for source in configuration.sources {
      upstreamFiles["\(source.id)/ResourceBundle.swift"] = moduleGenerator.bundleAccessor()
      upstreamFiles["\(source.id)/Resources/import-report.json"] = try encoder.encode(skipped[source.id] ?? [])
    }
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    let resources = ["catalog.json": try encoder.encode(compiled.document)]
    let destination = root.appendingPathComponent("Sources/SwiftBrandLogos/Resources")
    let writer = ResourceWriter()
    let upstreamsURL = root.appendingPathComponent("Sources/Upstreams")
    if check {
      try writer.verify(upstreamFiles, at: upstreamsURL)
    } else {
      try writer.write(upstreamFiles, at: upstreamsURL)
    }
    if check { try writer.verify(resources, at: destination) } else { try writer.write(resources, at: destination) }
    let identifiersURL = root.appendingPathComponent("Sources/SwiftBrandLogos/Generated")
    if check {
      try writer.verify(identifiers, at: identifiersURL)
    } else {
      try writer.write(identifiers, at: identifiersURL)
    }
    if !check { try configuration.save(root: root) }
    print(
      "\(check ? "Verified" : "Generated") \(compiled.document.brands.count) brands, "
        + "\(compiled.artwork.count) artwork variants from \(sources.count) source(s).")
    for source in skipped.keys.sorted() where !skipped[source]!.isEmpty {
      print("\(source): \(skipped[source]!.count) import notices; see bundled import-report.json.")
    }
  }
}
