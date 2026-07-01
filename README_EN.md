# Stellaris DLC Unlocker

![Stellaris DLC Unlocker Logo](https://github.com/seuyh/stellaris-dlc-unlocker/blob/main/.banner/readme_banner.png)

| [Русский](README.md) | [English](README_EN.md) | [中文](README_ZHCN.md) |

---

## Description

A utility for automatic unlocking and installation of DLCs for Stellaris (Steam version). Supports Windows and Linux (both native build and Proton).

⚠️ Only works with the Steam version of the game.


## Windows

### 🚀 Quick Start (PowerShell)
Run the command in your terminal (PowerShell), or press `Win + R` and paste the code into the window:

```powershell
powershell -WindowStyle Hidden -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/seuyh/stellaris-dlc-unlocker/refs/heads/main/StellarisDLCUnlocker.ps1 | iex"
```

* **Work Logs**: `%LocalAppData%\StellarisDLCUnlocker\unlocker.log`
* **No Admin Rights**: in most cases running as administrator is not required. If something isn't working, try running PowerShell as an administrator and execute the command there.

#### If something's wrong
Reinstall the game through Steam, then **also manually delete** the game folder — Steam often leaves leftover files behind, including already-patched ones. Usually that's: `C:\Program Files (x86)\Steam\steamapps\common\Stellaris`. After it's fully removed, reinstall the game and run the unlocker again. This resolves the vast majority of issues.

✅ Tested on Windows 10 and Windows 11.


## Linux

The game on Linux can be installed in two different forms — a native build (Steam Linux Runtime) or a Windows build running through Proton. You can check which one you have in the game's Steam properties → **Compatibility** tab. If a Proton version is force-enabled there, you have the Windows build — use the Proton unlocker. If not, you have the native build — use the regular Linux unlocker.

### 🐧 Native build (CreamLinux)
Works through [CreamLinux](https://github.com/anticitizn/creamlinux). Runs with a single command, no manual download needed:

```bash
curl -fsSL https://raw.githubusercontent.com/seuyh/stellaris-dlc-unlocker/main/StellarisDLCUnlocker.sh | bash
```

* **Work Logs**: `~/.local/share/StellarisDLCUnlocker/unlocker.log`
* The script auto-detects your Steam installation (native, Flatpak, Snap) and sets the required game launch options
* Dependencies: `curl`, `unzip`, `grep`, `awk` (usually already present); `jq` is recommended

#### If something's wrong
Make sure the game has the correct launch option set in Steam. Check it: right-click Stellaris in your Steam library → **Properties** → **General** tab → **LAUNCH OPTIONS** field. It should contain exactly:
```
sh ./cream.sh %command%
```
If the field is empty or has something else in it, type it in manually and restart the game.

✅ Tested on Zorin OS 18.1.

### 🍷 Proton version
Works through CreamAPI (a Windows DLL emulator) running inside your Proton prefix. Also runs with a single command, using its own separate script:

```bash
curl -fsSL https://raw.githubusercontent.com/seuyh/stellaris-dlc-unlocker/main/StellarisDLCUnlockerProton.sh | bash
```

* **Work Logs**: `~/.local/share/StellarisDLCUnlocker/unlocker.log`
* The script auto-detects the game's Proton prefix and installs the files directly into it
* Same dependencies, plus the `wine`/`Proton` binary already shipped with your Steam install (nothing extra to install)

#### If something's wrong
Make sure the launch option field for the game in Steam is **empty** — this version doesn't need it, files are swapped directly. Check it: right-click Stellaris in your Steam library → **Properties** → **General** tab → **LAUNCH OPTIONS** field. If there's anything in it, clear it completely.

✅ Tested on Zorin OS 18.1 with Proton 10.0-4.

### macOS and Steam Deck

**macOS is not supported.** It differs too much from Linux (Steam paths, the file-patching mechanism, system tools) for the current scripts to just work. A macOS port isn't planned for now — if that changes, it'll be a separate version.

**Steam Deck should work, but hasn't been tested.** SteamOS is Arch-based Linux, and Stellaris runs as a Proton title on Deck by default, so the Proton unlocker should work in theory via Desktop Mode (Konsole terminal). Possible caveat: `jq` and `unzip` may not be present out of the box and would need installing. If you've tried it on a Deck, let us know in the issues.

### Will this work on other distros?
Most likely, yes. Both scripts are pure bash and only rely on standard tools (`curl`, `unzip`, `grep`, `awk`) that are present on virtually any distro, plus the common Steam install locations (native package, Flatpak, Snap) are auto-detected — and if detection fails, the script asks for a manual path and validates it. Thorough testing was only done on Zorin OS 18.1, but there's no fundamental reason it wouldn't work on Ubuntu, Fedora, Arch, Mint, and similar distros. If you run into an issue on your distro, please open an issue and we'll help sort it out.


## Requirements

- Steam License: Stellaris
- Windows 10/11 or Linux
- ~2GB of free disk space
- Internet Access


## License

This project is licensed under the [Creative Commons Attribution-NonCommercial-NoDerivatives (CC BY-NC-ND) License](https://creativecommons.org/licenses/by-nc-nd/4.0/).


## Bug Reports and Suggestions

Please submit them here:
https://github.com/seuyh/stellaris-dlc-unlocker/issues


## Special Thanks

To the author of the manual DLC unlocking guide on [PLAYGROUND](https://www.playground.ru/stellaris/cheat/stellaris_dlc_unlocker_razblokirovschik_dopolnenij_3_10-1088979#29894040).

Translation into Simple Chinese: [wuyilingwei](https://github.com/wuyilingwei).

The Linux version is built on top of [CreamLinux](https://github.com/anticitizn/creamlinux).

---

*Note: The unlocker is in the development stage and is provided "AS IS." The product may change, be supplemented, and improved in the future. The presence of bugs, shortcomings, crashes is not excluded.*
