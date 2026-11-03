import Foundation

/// Checks XML structure and image references; asset-compiler support is verified separately.
final class SVGValidator: NSObject, XMLParserDelegate {
  private var rootSeen = false
  private var failure: String?
  private var depth = 0

  static func validate(_ data: Data, name: String) throws {
    let delegate = SVGValidator()
    let parser = XMLParser(data: data)
    parser.shouldProcessNamespaces = true
    parser.shouldResolveExternalEntities = false
    parser.delegate = delegate
    let parsed = parser.parse()
    if let failure = delegate.failure {
      throw UpdateError.invalid("\(name): \(failure)")
    }
    guard parsed, delegate.rootSeen else {
      let reason = parser.parserError?.localizedDescription ?? "Missing SVG root element."
      throw UpdateError.invalid("\(name): \(reason)")
    }
  }

  func parser(
    _ parser: XMLParser, didStartElement element: String, namespaceURI: String?,
    qualifiedName: String?, attributes: [String: String]
  ) {
    if depth == 0 {
      rootSeen = element == "svg" && [nil, "", "http://www.w3.org/2000/svg"].contains(namespaceURI)
      if !rootSeen { reject("Expected an SVG root element.", parser: parser) }
    }
    depth += 1
    if ["script", "foreignObject"].contains(element) {
      reject("Unsupported element: \(element).", parser: parser)
    }
    for (key, value) in attributes {
      let attribute = key.split(separator: ":").last.map(String.init) ?? key
      if attribute.hasPrefix("on") { reject("Unsupported event attribute: \(key).", parser: parser) }
      guard ["href", "src"].contains(attribute) else { continue }
      let reference = value.trimmingCharacters(in: .whitespacesAndNewlines)
      if reference.hasPrefix("#"), reference.count > 1 { continue }
      guard element == "image", reference.lowercased().hasPrefix("data:") else {
        reject("\(element) \(key) must reference this SVG or an embedded image.", parser: parser)
        continue
      }
      do {
        try EmbeddedImageValidator.validate(reference)
      } catch {
        reject("\(element) \(key): \(error)", parser: parser)
      }
    }
  }

  private func reject(_ reason: String, parser: XMLParser) {
    if failure == nil { failure = reason }
    parser.abortParsing()
  }

  func parser(
    _ parser: XMLParser, didEndElement element: String, namespaceURI: String?, qualifiedName: String?
  ) { depth -= 1 }
}
