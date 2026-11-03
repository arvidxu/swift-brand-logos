import Foundation

let root = URL(fileURLWithPath: #filePath).standardizedFileURL
  .deletingLastPathComponent().deletingLastPathComponent()
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
process.arguments =
  [
    "swift", "run", "--package-path", root.appendingPathComponent("Tools").path,
    "update-brand-logos", "--root", root.path,
  ] + CommandLine.arguments.dropFirst()

do {
  try process.run()
  process.waitUntilExit()
  exit(process.terminationStatus)
} catch {
  FileHandle.standardError.write(Data("Could not start logo updater: \(error)\n".utf8))
  exit(1)
}
