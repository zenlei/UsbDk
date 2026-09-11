# UsbDk ARM64 移植版

> **开发状态：Windows 11 ARM64 实验性移植，正在开发中**
>
> `arm64-port` 目前不建议日常使用，也不建议用于生产环境。本分支的目标
> 是在 Windows on ARM64 上使用原生 ARM64 的 `UsbDk.sys`，同时让系统模拟
> 运行的 x64/x86 上位机继续使用对应的用户态组件。驱动签名、真实 USB 设备
> 枚举、传输覆盖、回滚和 MSI 安装仍未达到正式发布标准。

[English README](README.md)

## 项目目标

本分支只维护 Windows 10/11 ARM64 目标，不再维护上游的 Win7、Win8、
Win8.1 和 XP 构建组合。

目标构建矩阵：

| 组件 | 目标架构 |
| --- | --- |
| `UsbDk.sys` | ARM64 原生内核驱动 |
| `UsbDkHelper.dll` | x64、x86 用户态 |
| `UsbDkController.exe` | x64、x86 用户态 |
| `UsbDkInstHelper.exe` | x64、x86 用户态 |

Windows 11 ARM64 可以模拟运行 x64/x86 用户态程序，但内核驱动必须是
ARM64。因此本分支不会生成 x86/x64 版本的 `UsbDk.sys`。

## 构建

仓库没有独立的 `Makefile`，Windows 构建入口是根目录的 `buildAll.bat`。
需要以下工具：

- Visual Studio 2022，安装 Desktop development with C++
- MSVC ARM64 工具，以及 x86/x64 工具和库
- 匹配的 Windows 10 SDK 和 WDK（验证使用 10.0.26100）
- WiX Toolset v3（仅生成 MSI 时需要）

在 VS2022 Developer Command Prompt 或 Developer PowerShell 中执行：

```cmd
buildAll.bat NOMSI NOSIGN
```

构建过程使用串行 MSBuild，并且只清理仓库内的 `Install` 和
`Install_Debug` 架构输出目录，不会对 `C:\`、`C:\Mac` 或共享目录递归操作。

ARM64 包目录：

```text
Install\ARM64\Win10Release\UsbDk_Package
├── UsbDk.sys                 ARM64 驱动
├── UsbDk.inf
├── UsbDkHelper.dll           x64 用户态
├── UsbDkController.exe       x64 用户态
├── UsbDkInstHelper.exe       x64 用户态
└── x86\                     x86 用户态
    ├── UsbDkHelper.dll
    ├── UsbDkController.exe
    └── UsbDkInstHelper.exe
```

`Install\x86` 和 `Install\x64` 只用于用户态构建输出，脚本会拒绝其中
出现 `UsbDk.sys`。安装 MSI 需要先安装 WiX，然后运行不带 `NOMSI` 的构建
命令；当前尚未完成 WiX 的实际 `candle.exe/light.exe` 验证。

## 当前验证

2026 年 9 月 11 日，在 Windows 11 ARM64 虚拟机中完成了以下检查：

- `buildAll.bat NOMSI NOSIGN` 返回成功，14 个构建目标均无警告和错误
- `UsbDk.sys` 的 PE 架构为 `AA64`
- x64 用户态 PE 架构为 `8664`
- x86 用户态 PE 架构为 `014C`
- ARM64 包包含 8 个文件
- x86/x64 输出目录均没有 `UsbDk.sys`
- x64 和 x86 的 `UsbDkController.exe -h` 均能启动

以上属于构建和启动冒烟测试，不代表驱动已经可以稳定工作。由于虚拟机
未启用测试签名且没有受信任的生产签名，Windows Code Integrity 会拒绝
加载当前驱动。以下项目仍待完成：

- 测试签名或正式签名环境下的驱动安装和服务启动
- 设备管理器状态及 USB 设备枚举
- 独占访问、控制/批量/等时传输
- 卸载、回滚和异常恢复
- ARM64 MSI 的实际安装测试

## 使用建议

当前版本仅适合开发、调试和问题定位。请使用 VM 快照进行实验，不要在
生产机器或重要 USB 设备上安装。后续代码更新统一在
`https://github.com/zenlei/UsbDk` 的 `arm64-port` 分支进行。
