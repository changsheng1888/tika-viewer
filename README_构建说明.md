# 长生卡工具 · iOS 只读版（SwiftUI 源码工程）

按已确认的四屏样式（文件库 / 卡片详情 / 对比 / 差异报告）写的原生 iOS 工程。
**只做查看与对比**，不做 NFC、不写卡、不碰 `.tlw` / `.tlk` 加密包。

---

## 一、这个文件夹里有什么

```
ios-card-viewer/
├─ TikaViewer.xcodeproj/           Xcode 工程（直接双击打开）
│  └─ project.pbxproj
├─ TikaViewer/
│  ├─ Sources/
│  │  ├─ App/
│  │  │  ├─ TikaViewerApp.swift    程序入口
│  │  │  └─ RootView.swift         四个页签 + 打开文件事件 + 报错弹窗
│  │  ├─ Theme/Theme.swift         色板、等宽/正文字体、十六进制格式化
│  │  ├─ Model/
│  │  │  ├─ CardDump.swift         一张卡的数据模型（块/扇区/UID/尾块判断）
│  │  │  ├─ DumpParser.swift       .dump / .bin / .mfd / HEX 文本解析
│  │  │  └─ CardDiff.swift         逐块逐字节比对 + txt 报告生成
│  │  ├─ Store/AppModel.swift      文件库持久化（Documents/library.json）
│  │  └─ Views/
│  │     ├─ Components.swift       芯片、扇区条、十六进制行、按钮样式
│  │     ├─ LibraryView.swift      ① 文件库：导入、列表、扇区条、快捷对比
│  │     ├─ CardDetailView.swift   ② 卡片详情：按扇区分组、64 块网格
│  │     ├─ BlockDetailView.swift  块弹层：16 字节 + 对比值 + 差异偏移
│  │     ├─ CompareView.swift      ③ 对比：A/B 选择、统计、仅差异/全部块
│  │     └─ ReportView.swift       ④ 差异报告：大数字、扇区分布、四列表格、导出
│  └─ Resources/
│     ├─ Info.plist                文件关联（dump/mfd/bin/hex/txt）+ 文件共享
│     └─ Assets.xcassets           AppIcon / AccentColor
├─ .github/workflows/build-ipa.yml  GitHub 自动打包（没 Mac 也能出 ipa）
├─ _selftest/                       纯逻辑自检（30 项断言 + 自检结果.txt）
├─ build_ipa.command               一键编译并打包未签名 ipa（需 macOS）
└─ README_构建说明.md              本文件
```

一共 13 个 Swift 文件，无第三方依赖，最低 iOS 16.0，仅 iPhone 竖屏。

---

## 二、有一台 Mac 时怎么出 ipa

1. 把整个 `ios-card-viewer` 文件夹拷到 Mac。
2. 双击 `TikaViewer.xcodeproj`，选中 `TikaViewer` target，在 Signing 里选一个自己的 Apple ID（Team）；
   或者完全不签名——工程默认 `CODE_SIGN_STYLE = Automatic`，**不填 Team 也能编**（产物未签名）。
3. 命令行最快：双击 `build_ipa.command`，产物是 `TikaViewer.ipa`（未签名）。
   或者手动：
   ```bash
   xcodebuild -project TikaViewer.xcodeproj -target TikaViewer \
     -configuration Release -sdk iphoneos -arch arm64 \
     CODE_SIGNING_ALLOWED=NO build
   mkdir Payload && cp -R build/Build/Products/Release-iphoneos/TikaViewer.app Payload/
   zip -qry TikaViewer.ipa Payload
   ```
4. 把 `TikaViewer.ipa` 传到 iPhone，用 **LiveContainer** 导入 → 自签安装。

> LiveContainer 会改写 bundle id，并在容器里运行。本工程不需要 NFC、不需要钥匙串、不需要 App Group，
> 因此在这套环境里功能不受影响；只有「在文件 App 里双击 .dump 自动用本应用打开」这种系统级文件关联可能不生效，
> 这时用应用内的「从「文件」导入 dump」即可。

---

## 三、工程万一打不开（兜底方案）

`project.pbxproj` 是手写的。若你的 Xcode 版本打开报错：

1. 在 Xcode 新建一个 iOS App 工程，名字填 `TikaViewer`，Interface 选 **SwiftUI**，语言 Swift。
2. 把本工程 `TikaViewer/Sources/` 下 **13 个 .swift 文件**拖进新工程（勾选 Copy items if needed、加入 TikaViewer target）。
3. 用本工程的 `Resources/Info.plist` 覆盖新工程的 Info.plist（或在 Build Settings 里把
   `INFOPLIST_FILE` 改成 `TikaViewer/Resources/Info.plist`，并把 `GENERATE_INFOPLIST_FILE` 设为 NO）。
4. 把 `Assets.xcassets` 拖进新工程，AppIcon 留空也能编（只是没有图标）。
5. 编出来的功能与本文档完全一致。

---

## 四、能做什么 / 不能做什么

**能**
- 导入 1024 / 4096 字节的 `.dump`（也认 `.bin` / `.mfd`，以及 2048 / 8192 个十六进制字符的 HEX 文本）。
- 文件库列表：UID、1K/4K、字节数、64 格扇区条、名称、读取时间、来源。
- 卡片详情：按扇区分组，每屏 4 块，尾块单独标 KEY A / 访问位 / KEY B；点块看 16 字节明细。
- 对比：选 A/B，统计差异扇区 / 块 / 字节，按「仅差异」或「全部块」浏览，差异字节标红。
- 差异报告：大数字、16 扇区分布、四列表格（位置 / 字节偏移 / A / B）、核对建议、导出 `.txt`、复制摘要。
- 数据只存本机 `Documents/library.json`，不联网、不改原始 dump 文件。

**不做（与最初约定一致）**
- 不做 NFC 读写：iOS 的 CoreNFC 不支持 MIFARE Classic，LiveContainer 里也拿不到 NFC 权限。
- 不解密 `.tlw` / `.tlk`：`.tlk` 需要师傅私钥，不建议放进 iOS 包。
- 不做格式化、写 M1/CUID —— 这些仍在安卓端与电脑版完成。

---

## 五、自检记录

### 1) 已在 Linux 上用 Swift 5.9.2 真编译器验证（不是"目测"）

- `swiftc -parse` 对 13 个 Swift 文件做语法解析：**全部通过**。
- `CardDump / DumpParser / CardDiff` 三个纯逻辑文件 + `AppModel`：**编译并类型检查通过**
  （`AppModel` 用 Combine 桩模块检查；`URL.startAccessingSecurityScopedResource` 是 Apple 平台独有 API，
  Linux 上按预期不识别，不影响 iOS 真机构建）。
- `_selftest/model_selftest.swift` 共 **30 项断言，30 PASS / 0 FAIL**，输出见 `_selftest/自检结果.txt`。
  覆盖：1024/4096 二进制解析、HEX 文本（空格/冒号/横线/换行）、空文件、512 字节、1000 字符 HEX、
  「纯十六进制文本恰好 1024 字节」不被误判成二进制、已知差异的块序号/字节偏移/扇区数/尾块计数、
  完全一致、尺寸不一致只比短边、UID/块数/类型/尾块/扇区标签、越界块、报告文本、Codable 往返。

运行方式（macOS 或 Linux 均可）：

```bash
cd ios-card-viewer
swiftc -O _selftest/HexStub.swift _selftest/model_selftest.swift \
  TikaViewer/Sources/Model/CardDump.swift \
  TikaViewer/Sources/Model/DumpParser.swift \
  TikaViewer/Sources/Model/CardDiff.swift -o /tmp/selftest
/tmp/selftest
```

> 注意：直接编译 `_selftest/model_selftest.swift` 时需把它复制成 `main.swift` 再编（Swift 顶层代码要求文件名 main.swift）。

### 2) 逐项功能对照

| 项 | 结果 |
| --- | --- |
| 解析：1024 / 4096 二进制 | 按字节数判定；纯 HEX 文本先按文本解析，避免误判 |
| 解析：HEX 文本 | 过滤分隔符，字符数须为 2048 或 8192，否则明确报错 |
| 解析：空文件 / 512 字节 / 1000 字符 | 分别报「文件是空的」「只支持 1024 或 4096 字节」「HEX 字符数不对」，不崩溃 |
| 比对：尺寸不同 | 只比短边，界面与报告都显式提示 |
| 比对：无差异 | 报告写「完全一致」，不编造差异 |
| 尾块识别 | `index % 4 == 3`；1K 扇区 S00–S15，4K 每格聚合 4 块 |
| 持久化 | 写入失败弹窗；删除当前卡自动回退选中项 |
| 打开外部文件 | `onOpenURL` + security scope，用完释放 |
| 报告导出 | 文本由实际差异数据生成；`ShareLink` 分享，不联网 |

### 3) 尚未验证的部分（如实说明）

本机是 Linux，没有 SwiftUI / Xcode，所以 **四个页面（视图层）只做了语法解析，没有做过编译与真机运行**。
第一次在 Mac 上打开时若出现红色报错，最可能是视图里的可选值解包或 `ForEach` 泛型推断；
把 Xcode 报错原文发我，我直接改，不用你研究。


| 项 | 结果 |
| --- | --- |
| 解析：1024 / 4096 二进制 | 按字节数判定，超界报「只支持 1024 或 4096 字节」 |
| 解析：HEX 文本 | 过滤空格/换行/冒号/横线，字符数须为 2048 或 8192，否则明确报错 |
| 解析：空文件 / 非文本二进制 | 分别给「文件是空的」「文件为 N 字节…」提示，不崩溃 |
| 比对：尺寸不同 | 只比短边，并在界面与报告里显式提示，不静默当成一致 |
| 比对：无差异 | 报告写「完全一致」，不编造差异 |
| 尾块识别 | `index % 4 == 3`；1K 扇区 S00–S15，4K 每格聚合 4 块 |
| 持久化 | 写入失败有弹窗提示；删除当前卡自动回退选中项 |
| 打开外部文件 | `onOpenURL` + `startAccessingSecurityScopedResource`，用完释放 |
| 报告导出 | 文本由实际差异数据生成；`ShareLink` 分享，不发网络 |

---

## 六、没有 Mac：用 GitHub 自动打包（免费）

原理：GitHub 免费提供苹果机器（macos runner），把这份源码推上去，它替你执行 `xcodebuild` 并产出 ipa。

**费用**：免费账号每月 2000 分钟额度，苹果机器按 **10 倍** 扣，等于 **200 分钟** macOS 时间。
这个工程一次构建约 3–5 分钟（扣 30–50 分钟额度），**每月够打几十次，不出额度就 0 元**。私有仓库同样在额度内。

### 步骤

1. 登录 GitHub → 右上角 `+` → New repository → 名字随便（如 `tika-viewer`）→ 选 **Private** → Create。
2. 进仓库 → `Add file` → `Upload files` → 把解压出来的这些东西拖进去：
   `TikaViewer/`、`TikaViewer.xcodeproj/`、`build_ipa.command`、`README_构建说明.md`、`_selftest/`
   → 底部 Commit changes。
   （网页拖拽可能漏掉 `.github` 这种点开头的文件夹，下一步单独建它。）
3. 建 workflow 文件：`Add file` → `Create new file`，文件名处直接填
   `.github/workflows/build-ipa.yml`，把压缩包里这个文件的内容整段粘进去 → Commit。
4. 顶部 `Actions` 标签 → 左边选 `Build iOS IPA` → 右边 `Run workflow` → 分支选 `main` → 绿色 `Run workflow`。
5. 等 3–5 分钟出现绿勾 → 点进这次运行 → 页面底部 **Artifacts** → 下载 `TikaViewer-ipa.zip`
   → 解压得到 `TikaViewer.ipa`（这就是你要的安装包，未签名）。
6. 把 ipa 传到 iPhone（微信文件传输助手 / 网盘 / 隔空投送都行）→ LiveContainer → 导入 ipa → 签名 → 启动。

> 以后每次改了代码，只要把改动提交到 `main`，它会自动重新打包，不用再点按钮。

### 构建失败怎么办

点开红色那一步，把日志里以 `error:` 开头的几行（或截图）发我，我直接改代码。
第一次在真正的 Xcode 上编译，最容易暴露的是视图层的类型细节——修起来都是几行的事。

## 七、版本

- 工程版本：`1.0`（build 1）
- Bundle id：`com.changsheng.tikaviewer`
- 最低系统：iOS 16.0
- 生成时间：2026-11-15
