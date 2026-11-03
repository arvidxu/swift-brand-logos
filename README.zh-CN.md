# SwiftBrandLogos

[English](README.md) | 简体中文

用于 SwiftUI 的品牌 Logo 库，提供本地资源、类型化品牌 ID、Logo 版本选择和品牌搜索。

## 目录

- [特性](#特性)
- [环境要求](#环境要求)
- [安装](#安装)
- [快速开始](#快速开始)
- [使用方法](#使用方法)
- [Logo 来源](#logo-来源)
- [参与贡献](#参与贡献)
- [许可证](#许可证)

## 特性

- **离线资源** — 直接从包内加载 Logo。
- **类型化标识符** — 通过 Swift 代码补全选择品牌和 Logo 版本。
- **多个版本** — 选择同一品牌的不同设计和版本。
- **品牌搜索** — 按品牌名称或 ID 搜索资源目录。
- **来源信息** — 查看 Logo 来源和随包附带的许可证。

## 环境要求

- Swift 5.9 或更高版本
- Xcode 15 或更高版本，以及目标平台 SDK

| 平台 | 最低版本 |
| --- | --- |
| iOS | 15.0 |
| macOS | 12.0 |
| watchOS | 8.0 |
| tvOS | 15.0 |
| visionOS | 1.0 |

## 安装

### Xcode

1. 在 Xcode 中打开你的应用项目，选择 **File → Add Package Dependencies…**。
2. 在搜索框中输入仓库地址：

   ```text
   https://github.com/arvidxu/swift-brand-logos.git
   ```

3. 将 **Dependency Rule** 设为 **Branch**，输入 `main`，点击 **Add Package**。
4. 勾选 `SwiftBrandLogos` 库，选择你的应用目标，点击 **Add Package**。

### Swift Package Manager

在 `Package.swift` 的 `dependencies` 中添加包依赖：

```swift
.package(
  url: "https://github.com/arvidxu/swift-brand-logos.git",
  branch: "main"
)
```

然后在目标的 `dependencies` 中添加库产品：

```swift
.product(name: "SwiftBrandLogos", package: "swift-brand-logos")
```

### 本地包

任选一种方式获取包：

**Git 克隆**

在准备存放包的目录中运行：

```sh
git clone https://github.com/arvidxu/swift-brand-logos.git
```

命令会在当前目录创建 `swift-brand-logos` 文件夹。

**ZIP 下载**

1. 打开[仓库页面](https://github.com/arvidxu/swift-brand-logos)，选择 **Code → Download ZIP**。
2. 解压下载的文件。`main` 分支的压缩包解压后目录名为 `swift-brand-logos-main`。

**添加到 Xcode**

1. 打开你的应用项目，选择 **File → Add Package Dependencies… → Add Local…**。
2. 选择克隆或解压后包含 `Package.swift` 的目录。
3. 将 `SwiftBrandLogos` 库添加到应用目标。

## 快速开始

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

`BrandLogo` 保留 Logo 的原始颜色和宽高比。尺寸和背景通过 SwiftUI 修饰符设置。

## 使用方法

### 品牌 ID

使用生成的 `BrandID`，也可以传入字符串：

```swift
BrandLogo(.github)
BrandLogo(id: "github")
```

### Logo 版本

传入品牌 ID 显示默认 Logo，使用 `variant:` 选择具体版本：

```swift
BrandLogo(.googleGmail)
BrandLogo(.googleGmail, variant: .svgLogosGoogleGmail)
BrandLogo(.googleGmail, variant: .svgLogosGoogleGmail2020)
```

两个版本 ID 分别对应 `google-gmail.svg` 和 `google-gmail-2020.svg`。

### 指定来源

使用 `source:` 选择指定集合中的 Logo：

```swift
BrandLogo(.google, source: "svg-logos")
```

### 查询与搜索

```swift
let catalog = try BrandCatalog.bundled()

let allBrands = catalog.brands
let results = catalog.search("Google")
let gmail = catalog.brand(.googleGmail)
let variants = gmail?.variants
let selected = gmail?.variant(.svgLogosGoogleGmail2020)
```

搜索匹配品牌名称和 ID，不区分大小写。空查询返回全部品牌。

品牌或版本查询无匹配项时返回 `nil`。索引数据缺失或无效时，加载操作抛出错误。

### SwiftUI Image

通过 `LogoVariant.image` 获取对应的 SwiftUI `Image`：

```swift
let catalog = try BrandCatalog.bundled()
let image = catalog.brand(.google)?.defaultVariant?.image
```

### 来源信息

```swift
let catalog = try BrandCatalog.bundled()
let sources = catalog.sources
let licenseURL = catalog.licenseURL(for: "svg-logos")
```

每个来源记录仓库 URL、commit SHA 和许可证。`licenseURL(for:)` 返回包内许可证文件的位置。

## Logo 来源

| 集合 | 来源 ID | 许可证 |
| --- | --- | --- |
| [SVG Logos](https://github.com/gilbarbara/logos) | `svg-logos` | [CC0 1.0](https://github.com/gilbarbara/logos/blob/22f03ffc4a652309d1fea4ade70f46e9e1d6602c/LICENSE.txt) |

Logo、许可证和来源记录按来源集中保存。

## 参与贡献

欢迎提交问题反馈、文档改进和代码贡献。开发环境配置、资源更新、测试和 Pull Request 要求见[贡献指南](CONTRIBUTING.zh-CN.md)。

## 许可证

库与工具代码采用 [MIT 许可证](LICENSE)。Logo 资源保留 [Logo 来源](#logo-来源)中列出的许可证。

品牌名称和商标归各自权利人所有。资源许可证不授予商标权。
