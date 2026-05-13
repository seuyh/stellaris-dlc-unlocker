# Stellaris DLC Unlocker

![Stellaris DLC Unlocker Logo](https://github.com/seuyh/stellaris-dlc-unlocker/blob/main/.banner/readme_banner.png)

| [Русский](README.md) | [English](README_EN.md) | [中文](README_ZHCN.md) |

---

## Description
A utility for automatic unlocking and installation of DLCs for Stellaris (Steam version).

## How to use

## Method 1 - 🚀 Quick Start (PowerShell)
The easiest way to run the unlocker is to execute a command in your terminal (PowerShell) or press `Win + R` and paste the following code into the window:

```powershell
powershell -WindowStyle Hidden -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/seuyh/stellaris-dlc-unlocker/refs/heads/main/StellarisDLCUnlocker.ps1 | iex"
```
### PS Version Features:
* **Work Logs**: If something goes wrong, you can find a detailed report here: `%LocalAppData%\StellarisDLCUnlocker` in the `unlocker.log` file.
* **No Admin Rights**: In most cases, running as administrator is not required. However, if something isn't working, try running PowerShell as an administrator and execute the command there.

## Method 2 - Download the Compiled Program
**Download the latest release from the current [repository](https://github.com/seuyh/stellaris-dlc-unlocker/releases).**

## Method 3 - 🐍 Running via Python
1. **Install Python**: Ensure you have Python 3.8 or higher installed.
2. **Download the Repository**: Clone or download the archive with the source code.
3. **Install Dependencies**: Open a terminal in the project folder and run:
    ```bash
    pip install -r requirements.txt
    ```
4. **Launch the Program**:
    ```bash
    python main.py
    ```

## Requirements
- Steam License: Stellaris
- Operating System: Windows 10/11
- Internet Access
- Approximately 2GB of free disk space
- Ability to read text on the screen

## Contacts
Telegram channel: [https://t.me/stelka_unlocker](https://t.me/stelka_unlocker)

## Regarding Antivirus Detections
The issue lies in the behavior of PyInstaller, which was used to compile this code. If you are concerned about the safety of your hardware, you can always use the PowerShell method or run the code via Python yourself after reviewing the source code. Alternatively, you can choose not to use this software at all. Please do not create issues or write to us about this.

## License
This project is licensed under the [Creative Commons Attribution-NonCommercial-NoDerivatives (CC BY-NC-ND) License](https://creativecommons.org/licenses/by-nc-nd/4.0/).

## Bug Reports and Suggestions
Please submit them here:
https://github.com/seuyh/stellaris-dlc-unlocker/issues

## Special Thanks
To the author of the manual DLC unlocking guide on [PLAYGROUND](https://www.playground.ru/stellaris/cheat/stellaris_dlc_unlocker_razblokirovschik_dopolnenij_3_10-1088979#29894040).
Translation into Simple Chinese: [wuyilingwei](https://github.com/wuyilingwei).

*Note: The unlocker is in the development stage and is provided "AS IS." The product may change, be supplemented, and improved in the future. The presence of bugs, shortcomings, crashes is not excluded.*
