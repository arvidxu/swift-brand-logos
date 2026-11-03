# Contributing to SwiftBrandLogos

English | [简体中文](CONTRIBUTING.zh-CN.md) · [Back to the usage guide](README.md)

This guide covers changes to SwiftBrandLogos itself: APIs, logo updates, upstream adapters, tests, and releases.

To use logos in your own app, see [Installation](README.md#installation) and [Usage](README.md#usage).

## Contents

- [Development Requirements](#development-requirements)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Upstream Configuration](#upstream-configuration)
- [Development Workflow](#development-workflow)
- [Submitting Changes](#submitting-changes)

## Development Requirements

| Purpose | Requirement |
| --- | --- |
| Run resource update tools | macOS 13 or later, Swift 5.9 or later, and Git |
| Compile artwork and test SwiftUI APIs | Xcode 15 or later and the target platform SDK |
| Fetch an uncached upstream commit | Network access to its upstream Git repository |

## Development Setup

Clone the repository and generate the upstream resources:

```sh
git clone https://github.com/arvidxu/swift-brand-logos.git
cd swift-brand-logos
swift scripts/update-brand-logos.swift
```

The updater fetches the latest commit from each upstream repository's default branch and generates the resources. After generation succeeds, it records the commit SHA in the `commit` field of [`Configuration/sources.json`](Configuration/sources.json).

## Project Structure

```text
Configuration/
  sources.json
Sources/
  SwiftBrandLogos/
    Generated/
    Resources/
      catalog.json
  Upstreams/
    svg-logos/
      ResourceBundle.swift
      Resources/
        Logos.xcassets/
        LICENSE.txt
        source.json
        import-report.json
Tests/
  SwiftBrandLogosTests/
Tools/
  Sources/
    LogoUpdaterCore/
    LogoUpdater/
  Tests/
scripts/
  update-brand-logos.swift
```

| Area | Responsibility |
| --- | --- |
| `Sources/SwiftBrandLogos` | Public API, unified catalog, typed IDs, and source bundle lookup |
| `Sources/Upstreams/<source-id>` | One generated source module containing its artwork and attribution files |
| `Tools/Sources/LogoUpdaterCore` | Adapters, repository caches, brand merging, resource generation, and verification |
| `scripts/update-brand-logos.swift` | Entry point for the separate tools package |

The tools package is not a runtime dependency. Generated source modules are internal package dependencies, not additional imports required from consumers.

## Upstream Configuration

[`Configuration/sources.json`](Configuration/sources.json) defines each source's repository URL, resource module, priority, license, and adapter. The updater writes `commit` automatically; omit this field when adding a source.

Default artwork selection follows source priority, source ID, and the adapter's artwork preference. Lower priority numbers take precedence. For SVG Logos, the adapter prefers `<brand>-icon.svg`, then `<brand>.svg`, then the remaining upstream files in their listed order.

When the same normalized brand ID has conflicting names, generation fails unless an explicit `brandMappings` entry resolves it. Mappings can merge different upstream brand IDs or separate unrelated brands. The compiler does not perform fuzzy identity matching.

## Development Workflow

### Updating Logos

Run the updater to fetch the latest upstream logos, then verify the generated resources:

```sh
swift scripts/update-brand-logos.swift
swift scripts/update-brand-logos.swift --check
```

`--check` recomputes expected output from the pinned source cache. It does not access the network or write generated resources. It fails for a missing cache, mismatched source checkout, or missing, changed, or extra output files.

To use an existing upstream checkout:

```sh
swift scripts/update-brand-logos.swift --source svg-logos=/absolute/path/to/logos
```

The checkout must match the configured repository URL and have no local changes. The updater reads its HEAD commit and records it after generation succeeds. With `--check`, the checkout must match the recorded commit. Updater Git operations affect source caches, not this repository's history or staging area.

Import notices are kept with each source in `Resources/import-report.json`. Rejected artwork is reported rather than silently replaced.

### Running Tests

```sh
swift test --package-path Tools
swift test
xcodebuild -scheme SwiftBrandLogos -destination 'platform=macOS' test
```

| Command | Coverage |
| --- | --- |
| `swift test --package-path Tools` | Adapters, source isolation, ID conflicts, generation, and resource verification |
| `swift test` | Catalog queries, typed IDs, and artwork selection; compiled-image test is skipped |
| `xcodebuild … test` | Library tests plus loading every artwork from its compiled source bundle |

Xcode compiles SVG asset catalogs. Command-line SwiftPM copies them without performing the same asset compilation.

### Adding an Upstream Adapter

1. Implement `SourceAdapter` and return normalized brands, artwork, and import notices.
2. Register the adapter in `AdapterRegistry`.
3. Add its source configuration, including the repository URL, a unique `resourceModule`, priority, and license path.
4. Resolve any brand identity conflicts through explicit mappings.
5. Generate resources, add adapter tests, and run the verification commands.
6. Update the source table and examples in both README files.

The package manifest and generated registry read source configuration to create separate resource modules. Public catalog and display APIs do not need source-specific changes.

### Versioning

[`VERSION`](VERSION) is the single source of truth for the package version. Use semantic versioning (`MAJOR.MINOR.PATCH`); release tags must match this file.

## Submitting Changes

Bug reports, documentation improvements, and upstream adapters are welcome.

For a bug report, include the brand ID, variant or source, expected behavior, platform, and Xcode/Swift version. Provide a small reproduction when possible.

For a new or corrected logo, check whether it should be added to the upstream collection. This project imports artwork through adapters; generated SVGs and identifier files should not be edited manually.

For a pull request:

- Keep changes focused and add tests for behavior changes.
- Preserve upstream attribution and licensing information.
- Follow the formatting in `.swift-format`.
- Keep the English and Chinese README and CONTRIBUTING files aligned in structure, examples, and behavior.
