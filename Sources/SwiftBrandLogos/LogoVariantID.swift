/// An exact upstream artwork identity, including its source and filename version.
public struct LogoVariantID: RawRepresentable, Codable, Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String

  public init(rawValue: String) { self.rawValue = rawValue }
  public init(stringLiteral value: String) { self.init(rawValue: value) }
}
