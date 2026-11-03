# SwiftBrandLogos

English | [简体中文](README.zh-CN.md)

A SwiftUI library for displaying brand logos from bundled resources, with typed brand IDs, logo variants, and a searchable catalog.

## Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage](#usage)
- [Logo Sources](#logo-sources)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Offline resources** — Load logos directly from the package.
- **Typed identifiers** — Select brands and logo variants with Swift code completion.
- **Logo variants** — Choose different designs and versions of the same brand.
- **Brand search** — Search the catalog by brand name or ID.
- **Source information** — Access logo provenance and bundled licenses.

## Requirements

- Swift 5.9 or later
- Xcode 15 or later with the target platform SDK

| Platform | Minimum version |
| --- | --- |
| iOS | 15.0 |
| macOS | 12.0 |
| watchOS | 8.0 |
| tvOS | 15.0 |
| visionOS | 1.0 |

## Installation

### Xcode

1. Open your app project in Xcode and select **File → Add Package Dependencies…**.
2. Enter the repository URL in the search field:

   ```text
   https://github.com/arvidxu/swift-brand-logos.git
   ```

3. Set **Dependency Rule** to **Branch**, enter `main`, and click **Add Package**.
4. Select the `SwiftBrandLogos` library, choose your app target, and click **Add Package**.

### Swift Package Manager

Add the package to `dependencies` in your `Package.swift`:

```swift
.package(
  url: "https://github.com/arvidxu/swift-brand-logos.git",
  branch: "main"
)
```

Then add its library product to your target's `dependencies`:

```swift
.product(name: "SwiftBrandLogos", package: "swift-brand-logos")
```

### Local Package

Obtain the package using either method:

**Git clone**

Run this command in the directory where you want to keep the package:

```sh
git clone https://github.com/arvidxu/swift-brand-logos.git
```

This creates a `swift-brand-logos` folder in the current directory.

**ZIP download**

1. Open the [repository](https://github.com/arvidxu/swift-brand-logos) and select **Code → Download ZIP**.
2. Extract the downloaded archive. The `main` branch archive extracts to `swift-brand-logos-main`.

**Add to Xcode**

1. Open your app project and select **File → Add Package Dependencies… → Add Local…**.
2. Select the cloned or extracted folder containing `Package.swift`.
3. Add the `SwiftBrandLogos` library to your app target.

## Quick Start

```swift
import SwiftUI
import SwiftBrandLogos

struct LogoView: View {
  var body: some View {
    BrandLogo(.google)
      .frame(width: 32, height: 32)
  }
}
```

`BrandLogo` preserves the logo's original colors and aspect ratio. Use SwiftUI modifiers to set its size and background.

## Usage

### Brand IDs

Use a generated `BrandID` or pass a string:

```swift
BrandLogo(.github)
BrandLogo(id: "github")
```

### Logo Variants

Pass a brand ID to display its default logo, or use `variant:` to select a specific version:

```swift
BrandLogo(.googleGmail)
BrandLogo(.googleGmail, variant: .svgLogosGoogleGmail)
BrandLogo(.googleGmail, variant: .svgLogosGoogleGmail2020)
```

The two variant IDs select `google-gmail.svg` and `google-gmail-2020.svg`, respectively.

### Source Selection

Use `source:` to select a logo from a specific collection:

```swift
BrandLogo(.google, source: "svg-logos")
```

### Catalog and Search

```swift
let catalog = try BrandCatalog.bundled()

let allBrands = catalog.brands
let results = catalog.search("Google")
let gmail = catalog.brand(.googleGmail)
let variants = gmail?.variants
let selected = gmail?.variant(.svgLogosGoogleGmail2020)
```

Search matches brand names and IDs without case sensitivity. An empty query returns all brands.

Brand and variant lookups return `nil` when no match exists. Loading the catalog throws if its data is missing or invalid.

### SwiftUI Image

Use `LogoVariant.image` to access the underlying SwiftUI `Image`:

```swift
let catalog = try BrandCatalog.bundled()
let image = catalog.brand(.google)?.defaultVariant?.image
```

### Source Metadata

```swift
let catalog = try BrandCatalog.bundled()
let sources = catalog.sources
let licenseURL = catalog.licenseURL(for: "svg-logos")
```

Each source records its repository URL, commit SHA, and license. `licenseURL(for:)` returns the location of its bundled license file.

## Logo Sources

| Collection | Source ID | License |
| --- | --- | --- |
| [SVG Logos](https://github.com/gilbarbara/logos) | `svg-logos` | [CC0 1.0](https://github.com/gilbarbara/logos/blob/22f03ffc4a652309d1fea4ade70f46e9e1d6602c/LICENSE.txt) |

Logos, licenses, and provenance records are grouped by source.

## Contributing

Bug reports, documentation improvements, and code contributions are welcome. See the [Contributing Guide](CONTRIBUTING.md) for development setup, resource updates, tests, and pull request guidelines.

## License

Library and tooling code are distributed under the [MIT License](LICENSE). Logo resources retain the licenses listed in [Logo Sources](#logo-sources).

Brand names and trademarks belong to their respective owners. Resource licenses do not grant trademark rights.
