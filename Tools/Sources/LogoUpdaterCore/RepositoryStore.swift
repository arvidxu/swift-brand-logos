import Foundation

struct RepositoryStore {
  let offline: Bool

  func resolveCommit(for source: SourceConfiguration, at checkout: URL? = nil) throws -> SourceConfiguration {
    guard !offline else { throw UpdateError.invalid("Cannot resolve an upstream commit in check mode.") }
    var resolved = source
    if let checkout {
      resolved.commit = try git(["rev-parse", "HEAD"], at: checkout)
      try validate(checkout, source: resolved)
    } else {
      let output = try git(["ls-remote", "--exit-code", source.repositoryURL, "HEAD"])
      let fields = output.split(whereSeparator: \.isWhitespace)
      guard fields.count == 2, fields[1] == "HEAD", Configuration.validCommit(String(fields[0])) else {
        throw UpdateError.invalid("Cannot resolve upstream HEAD: \(source.id)")
      }
      resolved.commit = String(fields[0])
    }
    return resolved
  }

  func checkout(_ source: SourceConfiguration) throws -> URL {
    guard let commit = source.commit, Configuration.validCommit(commit) else {
      throw UpdateError.invalid("No recorded commit for \(source.id). Run the updater first.")
    }
    let files = FileManager.default
    let cache = try files.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    let directory = cache.appendingPathComponent("SwiftBrandLogos/\(source.id)/\(commit)")
    if !files.fileExists(atPath: directory.path) {
      guard !offline else { throw UpdateError.invalid("Source cache missing. Run the updater first: \(source.id)") }
      try files.createDirectory(at: directory.deletingLastPathComponent(), withIntermediateDirectories: true)
      let staging = directory.deletingLastPathComponent().appendingPathComponent(".fetch-\(UUID().uuidString)")
      defer { try? files.removeItem(at: staging) }
      try files.createDirectory(at: staging, withIntermediateDirectories: true)
      _ = try git(["init", "--quiet"], at: staging)
      _ = try git(["remote", "add", "origin", source.repositoryURL], at: staging)
      _ = try git(["fetch", "--quiet", "--depth", "1", "origin", commit], at: staging)
      _ = try git(["checkout", "--quiet", "--detach", "FETCH_HEAD"], at: staging)
      try validate(staging, source: source)
      try files.moveItem(at: staging, to: directory)
    }
    try validate(directory, source: source)
    return directory
  }

  func validate(_ directory: URL, source: SourceConfiguration) throws {
    guard let commit = source.commit, Configuration.validCommit(commit),
      try git(["remote", "get-url", "origin"], at: directory) == source.repositoryURL,
      try git(["rev-parse", "HEAD"], at: directory) == commit,
      try git(["status", "--porcelain", "--untracked-files=all"], at: directory).isEmpty
    else { throw UpdateError.invalid("Source checkout does not match its pinned configuration: \(source.id)") }
  }

  private func git(_ arguments: [String], at directory: URL? = nil) throws -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
    process.arguments = arguments
    process.currentDirectoryURL = directory
    var environment = ProcessInfo.processInfo.environment
    environment["GIT_TERMINAL_PROMPT"] = "0"
    environment["GIT_OPTIONAL_LOCKS"] = "0"
    process.environment = environment
    let output = Pipe()
    process.standardOutput = output
    try process.run()
    let data = output.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
      throw UpdateError.invalid("Git failed: \(arguments.first ?? "git")")
    }
    return String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
