import SwiftUI

/// A resizable brand logo in its original colors.
public struct BrandLogo: View {
  private let id: BrandID
  private let sourceID: String?
  private let variantID: LogoVariantID?

  public init(_ id: BrandID, source: String? = nil) {
    self.id = id
    sourceID = source
    variantID = nil
  }

  public init(id: String, source: String? = nil) {
    self.init(BrandID(rawValue: id), source: source)
  }

  /// Displays an exact artwork belonging to the brand.
  public init(_ id: BrandID, variant: LogoVariantID) {
    self.id = id
    sourceID = nil
    variantID = variant
  }

  public init(id: String, variant: LogoVariantID) {
    self.init(BrandID(rawValue: id), variant: variant)
  }

  public var body: some View {
    if let brand = try? BrandCatalog.bundled().brand(id),
      let variant = resolveVariant(in: brand)
    {
      variant.image
        .resizable()
        .scaledToFit()
        .accessibilityLabel(brand.name)
    }
  }

  func resolveVariant(in brand: BrandInfo?) -> LogoVariant? {
    if let variantID { return brand?.variant(variantID) }
    if let sourceID { return brand?.variants.first { $0.sourceID == sourceID } }
    return brand?.defaultVariant
  }
}

extension LogoVariant {
  /// Use directly to apply your own sizing or rendering mode.
  public var image: Image {
    Image(assetName, bundle: SourceBundles.bundle(for: sourceID)).renderingMode(.original)
  }
}
