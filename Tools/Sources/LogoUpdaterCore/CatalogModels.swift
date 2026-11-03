import Foundation

struct CatalogDocument: Encodable {
  let schemaVersion = 1
  let kind = "brand-logo-resources"
  let sources: [CatalogSource]
  let brands: [CatalogBrand]
}

struct CatalogSource: Encodable {
  let id: String
  let repositoryURL: String
  let commit: String
  let license: String
  let licenseFile: String
}

struct CatalogBrand: Encodable {
  let id: String
  let name: String
  let defaultVariantID: String
  let variants: [CatalogVariant]
}

struct CatalogVariant: Encodable {
  let id: String
  let sourceID: String
  let sourceBrandID: String
  let sourceFile: String
  let sourceWebsite: String
  let assetName: String
  let sha256: String
}

struct LoadedSource {
  let configuration: SourceConfiguration
  let brands: [SourceBrand]
  let license: Data
}

struct CompiledCatalog {
  let document: CatalogDocument
  let artwork: [String: Data]
}
