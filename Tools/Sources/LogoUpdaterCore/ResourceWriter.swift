import Foundation

struct ResourceWriter {
  private let files = FileManager.default

  func verify(_ expected: [String: Data], at destination: URL) throws {
    let existing = try inventory(destination)
    let missing = Set(expected.keys).subtracting(existing.keys).sorted()
    let extra = Set(existing.keys).subtracting(expected.keys).sorted()
    let changed = expected.keys.filter { existing[$0] != nil && existing[$0] != expected[$0] }.sorted()
    guard missing.isEmpty, extra.isEmpty, changed.isEmpty else {
      throw UpdateError.invalid(
        "Stale resources: \(missing.count) missing, \(extra.count) extra, \(changed.count) changed. "
          + "First: \((missing + extra + changed).first ?? "unknown")")
    }
  }

  func write(_ expected: [String: Data], at destination: URL) throws {
    if (try? verify(expected, at: destination)) != nil { return }
    let parent = destination.deletingLastPathComponent()
    try files.createDirectory(at: parent, withIntermediateDirectories: true)
    let staging = parent.appendingPathComponent(".logos-\(UUID().uuidString)")
    let backup = parent.appendingPathComponent(".previous-\(UUID().uuidString)")
    defer { try? files.removeItem(at: staging) }
    try files.createDirectory(at: staging, withIntermediateDirectories: true)
    for (path, data) in expected {
      let url = staging.appendingPathComponent(path)
      try files.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
      try data.write(to: url)
    }
    try verify(expected, at: staging)
    let exists = files.fileExists(atPath: destination.path)
    if exists { try files.moveItem(at: destination, to: backup) }
    do {
      try files.moveItem(at: staging, to: destination)
    } catch {
      if exists { try files.moveItem(at: backup, to: destination) }
      throw error
    }
    if exists { try files.removeItem(at: backup) }
  }

  private func inventory(_ input: URL) throws -> [String: Data] {
    let directory = input.resolvingSymlinksInPath().standardizedFileURL
    guard files.fileExists(atPath: directory.path) else { return [:] }
    var result: [String: Data] = [:]
    for path in try files.subpathsOfDirectory(atPath: directory.path) {
      let url = directory.appendingPathComponent(path)
      let values = try url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
      guard values.isSymbolicLink != true else { throw UpdateError.invalid("Unexpected resource symlink: \(url.path)") }
      if values.isRegularFile == true {
        result[path] = try Data(contentsOf: url)
      }
    }
    return result
  }
}
