import Foundation

public struct Configuration: Codable {
  var sources: [SourceConfiguration]
  let brandMappings: [String: [String: String]]

  public static func load(root: URL) throws -> Self {
    let url = root.appendingPathComponent("Configuration/sources.json")
    let configuration = try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
    try configuration.validate()
    return configuration
  }

  func save(root: URL) throws {
    try validate()
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    var data = try encoder.encode(self)
    data.append(0x0A)
    try data.write(to: root.appendingPathComponent("Configuration/sources.json"), options: .atomic)
  }

  func validate() throws {
    guard !sources.isEmpty, Set(sources.map(\.id)).count == sources.count,
      Set(sources.map(\.resourceModule)).count == sources.count
    else {
      throw UpdateError.invalid("Source IDs must be unique and nonempty.")
    }
    for source in sources {
      guard Self.validID(source.id), URL(string: source.repositoryURL)?.scheme == "https",
        source.commit.map(Self.validCommit) ?? true,
        Self.safePath(source.licensePath),
        source.resourceModule.range(of: "^[A-Z][A-Za-z0-9]*Resources$", options: .regularExpression) != nil,
        source.resourceModule != "SwiftBrandLogos"
      else { throw UpdateError.invalid("Invalid source configuration: \(source.id)") }
    }
    for (source, mappings) in brandMappings {
      guard sources.contains(where: { $0.id == source }), mappings.values.allSatisfy(Self.validID) else {
        throw UpdateError.invalid("Invalid brand mapping for \(source)")
      }
    }
  }

  static func validID(_ value: String) -> Bool {
    value.range(of: "^[a-z0-9][a-z0-9._-]*$", options: .regularExpression) != nil
      && !value.contains("..")
  }

  static func validCommit(_ value: String) -> Bool {
    value.range(of: "^[a-f0-9]{40}$", options: .regularExpression) != nil
  }

  static func safePath(_ value: String) -> Bool {
    !value.isEmpty && !value.hasPrefix("/") && !value.split(separator: "/").contains("..")
  }
}

struct SourceConfiguration: Codable {
  let id: String
  let resourceModule: String
  let adapter: String
  let repositoryURL: String
  var commit: String?
  let priority: Int
  let license: String
  let licensePath: String
}

enum UpdateError: Error, CustomStringConvertible {
  case invalid(String)

  var description: String {
    switch self {
    case .invalid(let message): return message
    }
  }
}
