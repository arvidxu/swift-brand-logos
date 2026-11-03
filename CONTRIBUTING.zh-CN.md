# SwiftBrandLogos 贡献指南

[English](CONTRIBUTING.md) | 简体中文 · [返回使用文档](README.zh-CN.md)

本文用于维护 SwiftBrandLogos 本身，包括接口修改、Logo 更新、上游适配器、测试和发布。

在自己的 App 中使用 Logo，请参阅[安装](README.zh-CN.md#安装)和[使用方法](README.zh-CN.md#使用方法)。

## 目录

- [开发环境要求](#开发环境要求)
- [开发环境配置](#开发环境配置)
- [项目结构](#项目结构)
- [上游配置](#上游配置)
- [开发流程](#开发流程)
- [提交改动](#提交改动)

## 开发环境要求

| 用途 | 要求 |
| --- | --- |
| 运行资源更新工具 | macOS 13 或更高版本、Swift 5.9 或更高版本，以及 Git |
| 编译 Logo 资源、测试 SwiftUI 接口 | Xcode 15 或更高版本，以及目标平台 SDK |
| 获取尚未缓存的上游版本 | 可访问对应上游 Git 仓库的网络连接 |

## 开发环境配置

克隆仓库并生成上游资源：

```sh
git clone https://github.com/arvidxu/swift-brand-logos.git
cd swift-brand-logos
swift scripts/update-brand-logos.swift
```

更新工具会从各上游仓库的默认分支获取最新 commit 并生成资源。生成成功后，自动将 commit SHA 写入 [`Configuration/sources.json`](Configuration/sources.json) 的 `commit` 字段。

## 项目结构

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

| 位置 | 职责 |
| --- | --- |
| `Sources/SwiftBrandLogos` | 公共 API、统一索引、类型化 ID 和来源资源包查询 |
| `Sources/Upstreams/<source-id>` | 每个来源独立生成的模块，集中保存 Logo 和署名信息文件 |
| `Tools/Sources/LogoUpdaterCore` | 适配器、仓库缓存、品牌归并、资源生成与校验 |
| `scripts/update-brand-logos.swift` | 独立工具包的调用入口 |

工具包不作为运行时依赖。生成的来源模块属于包内部依赖，使用方无需额外导入。

## 上游配置

[`Configuration/sources.json`](Configuration/sources.json) 配置各来源的仓库 URL、资源模块、优先级、许可证和适配器。`commit` 由工具自动写入，添加来源时无需填写。

默认 Logo 依次按照来源优先级、来源 ID 和适配器的选择顺序确定，优先级数值越小越靠前。对于 SVG Logos，适配器优先选择 `<brand>-icon.svg`，其次是 `<brand>.svg`，其余文件按上游列出的顺序选择。

相同的规范化品牌 ID 对应不同名称时，必须通过显式 `brandMappings` 解决冲突，否则生成失败。映射可以归并同一品牌在不同来源中的 ID，也可以拆分实际不相关的品牌；编译器不进行模糊身份匹配。

## 开发流程

### 更新 Logo

运行更新工具获取上游最新 Logo，然后校验生成的资源：

```sh
swift scripts/update-brand-logos.swift
swift scripts/update-brand-logos.swift --check
```

`--check` 根据固定版本的上游缓存重新计算预期产物，不访问网络，也不写入生成资源。缓存缺失、上游检出状态不匹配，或产物存在缺失、改动、多余文件时，校验会失败。

使用已有的上游检出目录：

```sh
swift scripts/update-brand-logos.swift --source svg-logos=/absolute/path/to/logos
```

该目录的仓库 URL 必须与配置一致，且不能存在本地改动。工具会读取其 HEAD commit，并在生成成功后记录；使用 `--check` 时，该目录必须与已记录的 commit 一致。更新工具的 Git 操作仅作用于上游缓存，不修改本仓库的历史或暂存区。

导入提示与各来源一起保存在 `Resources/import-report.json` 中。被拒绝的 Logo 文件会记录在报告中。

### 运行测试

```sh
swift test --package-path Tools
swift test
xcodebuild -scheme SwiftBrandLogos -destination 'platform=macOS' test
```

| 命令 | 验证范围 |
| --- | --- |
| `swift test --package-path Tools` | 适配器、来源隔离、ID 冲突、生成逻辑和资源校验 |
| `swift test` | 索引查询、类型化 ID 和 Logo 选择；跳过编译后图像加载测试 |
| `xcodebuild … test` | 库测试，以及从各来源编译后的资源包中加载全部 Logo |

Xcode 负责 SVG 资源目录编译。命令行 SwiftPM 会复制这些资源，不执行相同的资源编译过程。

### 添加上游适配器

1. 实现 `SourceAdapter`，返回标准化的品牌、Logo 和导入提示。
2. 在 `AdapterRegistry` 中注册适配器。
3. 添加来源配置，包含仓库 URL、唯一的 `resourceModule`、优先级和许可证路径。
4. 通过显式映射解决品牌身份冲突。
5. 生成资源、添加适配器测试，并运行校验命令。
6. 同步更新两份 README 的来源表和示例。

包清单和生成的注册表会读取来源配置，建立独立资源模块。公共索引和显示 API 不需要针对各来源修改。

### 版本管理

包版本号统一维护在 [`VERSION`](VERSION) 中。遵循语义化版本规则（`主版本.次版本.修订版本`），发布标签必须与该文件一致。

## 提交改动

欢迎提交问题反馈、文档改进和上游适配器。

反馈问题时，请提供品牌 ID、Logo 版本或来源、预期行为、平台，以及 Xcode / Swift 版本；可以的话，附上最小复现示例。

新增或修正 Logo 时，请先确认是否应向上游图标集合贡献。本项目通过适配器导入 Logo，不应手动编辑生成的 SVG 或标识符文件。

提交 Pull Request 时：

- 保持改动范围集中，为行为变化添加测试。
- 保留上游署名与许可证信息。
- 遵循 `.swift-format` 中的格式配置。
- 保持中英文 README 及 CONTRIBUTING 的对应章节、示例和行为说明一致。
