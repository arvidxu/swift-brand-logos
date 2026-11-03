import Foundation
import LogoUpdaterCore

do {
  var arguments = Array(CommandLine.arguments.dropFirst())
  if arguments.contains("--help") {
    print("Usage: update-brand-logos --root <package> [--check] [--source <id>=<checkout>]")
    print("Updates from upstream HEAD and records the commit after resource generation succeeds.")
    print("--check verifies the recorded commit offline without changing files.")
    exit(0)
  }
  var root: URL?
  var check = false
  var overrides: [String: URL] = [:]
  while !arguments.isEmpty {
    let argument = arguments.removeFirst()
    switch argument {
    case "--check": check = true
    case "--root":
      guard !arguments.isEmpty else { throw CLIError.usage }
      root = URL(fileURLWithPath: arguments.removeFirst()).standardizedFileURL
    case "--source":
      guard !arguments.isEmpty else { throw CLIError.usage }
      let parts = arguments.removeFirst().split(separator: "=", maxSplits: 1).map(String.init)
      guard parts.count == 2, !parts[0].isEmpty, !parts[1].isEmpty, overrides[parts[0]] == nil else {
        throw CLIError.usage
      }
      overrides[parts[0]] = URL(fileURLWithPath: parts[1])
    default: throw CLIError.usage
    }
  }
  guard let root else { throw CLIError.usage }
  try Updater().run(root: root, check: check, sourceOverrides: overrides)
} catch {
  FileHandle.standardError.write(Data("Logo update failed: \(error)\n".utf8))
  exit(1)
}

enum CLIError: Error, CustomStringConvertible {
  case usage

  var description: String {
    "Usage: update-brand-logos --root <package> [--check] [--source <id>=<checkout>]"
  }
}
