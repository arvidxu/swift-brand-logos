import Foundation

struct SourceModuleGenerator {
  func bundleAccessor() -> Data {
    Data(
      """
      // Generated source resource module. Do not edit.
      import Foundation

      package enum ResourceBundle {
        package static let value = Bundle.module
      }

      """.utf8)
  }

  func registry(_ sources: [SourceConfiguration]) -> Data {
    let sorted = sources.sorted { $0.id < $1.id }
    var lines = ["// Generated source bundle registry. Do not edit.", "import Foundation"]
    lines += sorted.map { "import \($0.resourceModule)" }
    lines += [
      "", "enum SourceBundles {", "  static func bundle(for sourceID: String) -> Bundle? {",
      "    switch sourceID {",
    ]
    lines += sorted.map { "    case \"\($0.id)\": return \($0.resourceModule).ResourceBundle.value" }
    lines += ["    default: return nil", "    }", "  }", "}"]
    return Data((lines.joined(separator: "\n") + "\n").utf8)
  }
}
