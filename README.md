# UnreadBadge（未读角标）

一个原生 macOS 菜单栏应用：读取 Dock 中指定应用公开的未读角标，并在可拖动的悬浮窗中集中展示。

![未读角标统一展示](AppStoreAssets/01-unified-unread.png)

## 功能

- 集中展示多个应用的图标、名称和未读数
- 从运行中的应用或本地 `.app` 添加监控项
- 支持自定义图标、尺寸、背景颜色和透明度
- 支持始终置顶、点击激活应用和保存悬浮窗位置
- 原生 Swift/AppKit 实现，不依赖第三方运行库
- 同时支持 Apple Silicon 与 Intel Mac

## 系统要求

- macOS 13 Ventura 或更高版本
- 辅助功能权限，用于读取 Dock 的 `AXStatusLabel` 和激活应用窗口

UnreadBadge 只读取 macOS Dock 对外提供的角标文本，不读取聊天内容，也不会把未读信息上传到服务器。完整说明见 [安全政策](SECURITY.md)。

## 安装

从项目的 [GitHub Releases](https://github.com/liuxindtc/unread-badge/releases) 下载最新 ZIP，解压后将 `UnreadBadge.app` 移入“应用程序”文件夹。

第一次启动后，前往：

```text
系统设置 → 隐私与安全性 → 辅助功能
```

允许 UnreadBadge 使用辅助功能。若 macOS 阻止首次打开，请在 Finder 中右键应用并选择“打开”，或在“隐私与安全性”页面确认打开。

> 只有目标应用把未读数显示在 Dock 时，UnreadBadge 才能读取该数值。空值、`0` 和 `-` 会被视为无未读；其他非空文本（例如 `4`、`99+`）会直接显示。

## 许可证

本项目基于 [MIT License](LICENSE) 开源。
