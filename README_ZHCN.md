# 群星DLC解锁器

![Stellaris DLC Unlocker Logo](https://github.com/seuyh/stellaris-dlc-unlocker/blob/main/.banner/readme_banner.png)

| [Русский](README.md) | [English](README_EN.md) | [中文](README_ZHCN.md) |

---

## 项目描述
用于自动解锁和安装 Stellaris（Steam 版）DLC 的工具。

## 使用方法

## 方法 1 - 🚀 快速启动 (PowerShell)
运行解锁器最简单的方法是在终端 (PowerShell) 中执行以下命令，或者按下 `Win + R` 并将代码粘贴到运行窗口中：

```powershell
powershell -ExecutionPolicy Bypass -Command "irm [https://raw.githubusercontent.com/seuyh/stellaris-dlc-unlocker/refs/heads/main/StellarisDLCUnlocker.ps1](https://raw.githubusercontent.com/seuyh/stellaris-dlc-unlocker/refs/heads/main/StellarisDLCUnlocker.ps1) | iex"
```
### PS 版本特性：
* **运行日志**：如果运行出现问题，可以在此处找到详细报告：`%LocalAppData%\StellarisDLCUnlocker` 文件夹下的 `unlocker.log` 文件。
* **无需管理员权限**：在大多数情况下，不需要以管理员身份运行。但如果运行不正常，请尝试以管理员身份运行 PowerShell 并再次执行该命令。

## 方法 2 - 下载已编译的程序
**请从当前的 [仓库发布页面](https://github.com/seuyh/stellaris-dlc-unlocker/releases) 下载最新版本。**

## 方法 3 - 🐍 通过 Python 运行
1. **安装 Python**：确保已安装 Python 3.8 或更高版本。
2. **下载仓库**：克隆或下载包含源代码的压缩包。
3. **安装依赖**：在项目文件夹中打开终端并运行：
    ```bash
    pip install -r requirements.txt
    ```
4. **启动程序**：
    ```bash
    python main.py
    ```

## 系统要求
- Steam 授权：Stellaris 正版游戏
- 操作系统：Windows 10/11
- 互联网访问
- 约 2GB 的可用磁盘空间
- 具备阅读屏幕文字的能力

## 联系方式
Telegram 频道：[https://t.me/stelka_unlocker](https://t.me/stelka_unlocker)

## 关于杀毒软件误报
此类问题源于用于打包代码的 PyInstaller 运行机制。如果您担心硬件安全，可以随时使用 PowerShell 方法，或者在阅读源代码后自行通过 Python 运行代码。此外，您也可以选择完全不使用本软件。请不要为此创建 Issue 或反馈相关信息。

## 许可协议
本项目采用 [知识共享署名-非商业性使用-禁止演绎 (CC BY-NC-ND) 4.0 许可协议](https://creativecommons.org/licenses/by-nc-nd/4.0/deed.zh) 进行许可。

## 错误报告与建议请提交至
https://github.com/seuyh/stellaris-dlc-unlocker/issues

## 特别鸣谢
感谢在 [PLAYGROUND](https://www.playground.ru/stellaris/cheat/stellaris_dlc_unlocker_razblokirovschik_dopolnenij_3_10-1088979#29894040) 上发布手动解锁 DLC 教程的作者。

翻译成简体中文 [wuyilingwei](https://github.com/wuyilingwei)。

注：解锁器处于开发阶段，并且以“按原样”提供。产品可能会变更、补充和改进。不排除存在缺陷、不足、崩溃的可能。
