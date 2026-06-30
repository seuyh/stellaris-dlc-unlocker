# 群星DLC解锁器

![Stellaris DLC Unlocker Logo](https://github.com/seuyh/stellaris-dlc-unlocker/blob/main/.banner/readme_banner.png)

| [Русский](README.md) | [English](README_EN.md) | [中文](README_ZHCN.md) |

---

## 项目描述

用于自动解锁和安装 Stellaris（Steam 版）DLC 的工具。支持 Windows 和 Linux（原生版本与 Proton 版本）。

⚠️ 仅适用于 Steam 版游戏。


## Windows

### 🚀 快速启动 (PowerShell)
在终端 (PowerShell) 中执行以下命令，或者按下 `Win + R` 并将代码粘贴到运行窗口中：

```powershell
powershell -WindowStyle Hidden -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/seuyh/stellaris-dlc-unlocker/refs/heads/main/StellarisDLCUnlocker.ps1 | iex"
```

* **运行日志**：`%LocalAppData%\StellarisDLCUnlocker\unlocker.log`
* **无需管理员权限**：在大多数情况下，不需要以管理员身份运行。但如果运行不正常，请尝试以管理员身份运行 PowerShell 并再次执行该命令。

#### 如果出现问题
请先通过 Steam 卸载游戏，然后**额外手动删除**游戏文件夹——Steam 卸载时经常会留下残留文件，包括已被修补过的文件。通常路径为：`C:\Program Files (x86)\Steam\steamapps\common\Stellaris`。彻底删除后重新安装游戏，再运行解锁器。这能解决绝大多数问题。

✅ 已在 Windows 10 和 Windows 11 上测试。


## Linux

Linux 上的游戏可能以两种不同形式安装——原生版本（Steam Linux Runtime）或通过 Proton 运行的 Windows 版本。可以在 Steam 游戏属性的 **Compatibility** 选项卡中查看您是哪一种。如果那里强制启用了某个 Proton 版本，说明您安装的是 Windows 版本，请使用 Proton 解锁器；如果没有启用，则是原生版本，请使用普通的 Linux 解锁器。

### 🐧 原生版本 (CreamLinux)
基于 [CreamLinux](https://github.com/anticitizn/creamlinux) 实现。一条命令即可运行，无需手动下载：

```bash
curl -fsSL https://raw.githubusercontent.com/seuyh/stellaris-dlc-unlocker/main/StellarisDLCUnlocker.sh | bash
```

* **运行日志**：`~/.local/share/StellarisDLCUnlocker/unlocker.log`
* 脚本会自动检测您的 Steam 安装方式（原生、Flatpak、Snap）并设置所需的游戏启动参数
* 依赖项：`curl`、`unzip`、`grep`、`awk`（系统通常已自带）；建议安装 `jq`

#### 如果出现问题
请确认游戏在 Steam 中设置了正确的启动参数。查看方法：在 Steam 库中右键 Stellaris → **属性** → **常规** 选项卡 → **启动选项** 字段。其内容应该正好是：
```
sh ./cream.sh %command%
```
如果该字段为空或内容不同，请手动填入该字符串并重新启动游戏。

✅ 已在 Zorin OS 18.1 上测试。

### 🍷 Proton 版本
基于 CreamAPI（Windows DLL 模拟器）实现，在您的 Proton 前缀内运行。同样一条命令即可运行，使用独立的脚本：

```bash
curl -fsSL https://raw.githubusercontent.com/seuyh/stellaris-dlc-unlocker/main/StellarisDLCUnlockerProton.sh | bash
```

* **运行日志**：`~/.local/share/StellarisDLCUnlocker/unlocker.log`
* 脚本会自动找到游戏的 Proton 前缀，并将文件直接安装到其中
* 依赖项相同，另外会使用您 Steam 安装自带的 `wine`/`Proton`（无需额外安装）

#### 如果出现问题
请确认游戏在 Steam 中的启动选项字段是**空的**——此版本不需要任何启动参数，文件是直接替换的。查看方法：在 Steam 库中右键 Stellaris → **属性** → **常规** 选项卡 → **启动选项** 字段。如果其中有内容，请将其完全清空。

✅ 已在 Zorin OS 18.1（Proton 10.0-4）上测试。

### macOS 和 Steam Deck

**不支持 macOS。** Steam 路径、底层文件机制（Linux 上的 `LD_PRELOAD`/`.so` 对比 macOS 上的 `DYLD_INSERT_LIBRARIES`/Mach-O），甚至基础工具（macOS 默认自带的是 BSD 版 `sed` 而非 GNU 版）差异都很大，导致现有脚本在 macOS 上根本无法运行，需要针对该平台单独开发一个版本。

**Steam Deck 理论上应该可行，但尚未测试。** SteamOS 基于 Arch Linux，Stellaris 在 Deck 上默认作为 Proton 游戏运行，因此理论上可以在桌面模式（Konsole 终端）下使用 Proton 版解锁器。可能存在的问题：`jq` 和 `unzip` 可能未预装，需要手动安装。如果您在 Deck 上尝试过，欢迎在 issues 中反馈结果。

### 在其他发行版上能正常工作吗？
大概率可以。两个脚本均为纯 bash 编写，仅依赖几乎所有发行版都自带的标准工具（`curl`、`unzip`、`grep`、`awk`），常见的 Steam 安装路径（原生、Flatpak、Snap）也会自动检测——如果检测失败，脚本会请求手动输入路径并进行校验。目前仅在 Zorin OS 18.1 上进行了充分测试，但没有理由认为在 Ubuntu、Fedora、Arch、Mint 等发行版上无法运行。如果您在自己的发行版上遇到问题，欢迎提交 issue，我们会协助排查。


## 系统要求

- Steam 授权：Stellaris 正版游戏
- Windows 10/11 或 Linux
- 约 2GB 的可用磁盘空间
- 互联网访问


## 许可协议

本项目采用 [知识共享署名-非商业性使用-禁止演绎 (CC BY-NC-ND) 4.0 许可协议](https://creativecommons.org/licenses/by-nc-nd/4.0/deed.zh) 进行许可。


## 错误报告与建议请提交至

https://github.com/seuyh/stellaris-dlc-unlocker/issues


## 特别鸣谢

感谢在 [PLAYGROUND](https://www.playground.ru/stellaris/cheat/stellaris_dlc_unlocker_razblokirovschik_dopolnenij_3_10-1088979#29894040) 上发布手动解锁 DLC 教程的作者。

翻译成简体中文 [wuyilingwei](https://github.com/wuyilingwei)。

Linux 版本基于 [CreamLinux](https://github.com/anticitizn/creamlinux) 构建。

---

注：解锁器处于开发阶段，并且以"按原样"提供。产品可能会变更、补充和改进。不排除存在缺陷、不足、崩溃的可能。
