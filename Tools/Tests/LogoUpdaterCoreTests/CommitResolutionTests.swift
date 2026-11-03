import Foundation
import XCTest

@testable import LogoUpdaterCore

final class CommitResolutionTests: XCTestCase {
  func testRemoteHEADIsResolvedAgainAfterNewCommit() throws {
    let directory = try makeRepository()
    defer { try? FileManager.default.removeItem(at: directory) }
    let source = configuration(repositoryURL: directory.absoluteString)
    let store = RepositoryStore(offline: false)
    let first = try store.resolveCommit(for: source)
    XCTAssertEqual(first.commit, try git(["rev-parse", "HEAD"], at: directory))
    _ = try git(["commit", "--quiet", "--allow-empty", "-m", "Next fixture"], at: directory)
    let second = try store.resolveCommit(for: first)
    XCTAssertEqual(second.commit, try git(["rev-parse", "HEAD"], at: directory))
    XCTAssertNotEqual(first.commit, second.commit)
    XCTAssertThrowsError(try RepositoryStore(offline: true).resolveCommit(for: source))
    XCTAssertThrowsError(try RepositoryStore(offline: true).checkout(source))
  }

  func testUpdaterRecordsSuccessfulCommitAndPreservesItOnFailure() throws {
    let checkout = try makeRepository()
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer {
      try? FileManager.default.removeItem(at: checkout)
      try? FileManager.default.removeItem(at: root)
    }
    let source = configuration(repositoryURL: "https://example.com/logos.git")
    _ = try git(["remote", "add", "origin", source.repositoryURL], at: checkout)
    try FileManager.default.createDirectory(
      at: checkout.appendingPathComponent("logos"), withIntermediateDirectories: true)
    try Data("<svg><path fill='#ff0000'/></svg>".utf8)
      .write(to: checkout.appendingPathComponent("logos/example.svg"))
    try Data("Fixture license".utf8).write(to: checkout.appendingPathComponent("LICENSE.txt"))
    try Data(
      """
      [{"name":"Example","shortname":"example","url":"https://example.com","files":["example.svg"]}]
      """.utf8
    ).write(to: checkout.appendingPathComponent("logos.json"))
    _ = try git(["add", "."], at: checkout)
    _ = try git(["commit", "--quiet", "-m", "Add fixture logos"], at: checkout)
    try FileManager.default.createDirectory(
      at: root.appendingPathComponent("Configuration"), withIntermediateDirectories: true)
    try Configuration(sources: [source], brandMappings: [:]).save(root: root)
    let updater = Updater()
    let overrides = [source.id: checkout]
    XCTAssertThrowsError(try updater.run(root: root, check: true, sourceOverrides: overrides))
    try updater.run(root: root, check: false, sourceOverrides: overrides)
    XCTAssertEqual(
      try Configuration.load(root: root).sources.first?.commit, try git(["rev-parse", "HEAD"], at: checkout))
    let configURL = root.appendingPathComponent("Configuration/sources.json")
    let savedConfiguration = try Data(contentsOf: configURL)
    let catalogURL = root.appendingPathComponent("Sources/SwiftBrandLogos/Resources/catalog.json")
    let savedCatalog = try Data(contentsOf: catalogURL)
    let catalog = try XCTUnwrap(JSONSerialization.jsonObject(with: savedCatalog) as? [String: Any])
    let sources = try XCTUnwrap(catalog["sources"] as? [[String: Any]])
    XCTAssertEqual(sources.first?["commit"] as? String, try git(["rev-parse", "HEAD"], at: checkout))
    XCTAssertNil(sources.first?["revision"])
    try updater.run(root: root, check: true, sourceOverrides: overrides)
    XCTAssertEqual(try Data(contentsOf: configURL), savedConfiguration)
    XCTAssertEqual(try Data(contentsOf: catalogURL), savedCatalog)

    try Data("invalid JSON".utf8).write(to: checkout.appendingPathComponent("logos.json"))
    XCTAssertThrowsError(try updater.run(root: root, check: false, sourceOverrides: overrides))
    _ = try git(["add", "."], at: checkout)
    _ = try git(["commit", "--quiet", "-m", "Invalid fixture"], at: checkout)
    XCTAssertThrowsError(try updater.run(root: root, check: false, sourceOverrides: overrides))
    XCTAssertEqual(try Data(contentsOf: configURL), savedConfiguration)
    XCTAssertEqual(try Data(contentsOf: catalogURL), savedCatalog)
  }

  private func configuration(repositoryURL: String) -> SourceConfiguration {
    SourceConfiguration(
      id: "fixture", resourceModule: "FixtureResources", adapter: "svg-logos",
      repositoryURL: repositoryURL, commit: nil, priority: 1, license: "MIT", licensePath: "LICENSE.txt")
  }

  private func makeRepository() throws -> URL {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    _ = try git(["init", "--quiet"], at: directory)
    _ = try git(["commit", "--quiet", "--allow-empty", "-m", "Fixture"], at: directory)
    return directory
  }

  private func git(_ arguments: [String], at directory: URL) throws -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
    process.arguments =
      [
        "-c", "user.name=Logo Tests", "-c", "user.email=tests@example.com", "-c", "commit.gpgsign=false",
        "-c", "core.hooksPath=/dev/null",
      ] + arguments
    process.currentDirectoryURL = directory
    let output = Pipe()
    process.standardOutput = output
    try process.run()
    let data = output.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else { throw UpdateError.invalid("Fixture Git command failed") }
    return String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
