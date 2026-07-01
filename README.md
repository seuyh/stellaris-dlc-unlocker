# Stellaris DLC Unlocker

![Stellaris DLC Unlocker Logo](https://github.com/seuyh/stellaris-dlc-unlocker/blob/main/.banner/readme_banner.png)

| [Русский](README.md) | [English](README_EN.md) | [中文](README_ZHCN.md) |

---

## Описание

Утилита для автоматической разблокировки и установки DLC для игры Stellaris (Steam версия). Поддерживает Windows и Linux (нативную сборку и версию через Proton).

⚠️ Работает только со Steam-версией игры.


## Windows

### 🚀 Быстрый запуск (PowerShell)
Выполните команду в терминале (PowerShell), либо нажмите win+r и вставьте код в открывшееся окно:

```powershell
powershell -WindowStyle Hidden -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/seuyh/stellaris-dlc-unlocker/refs/heads/main/StellarisDLCUnlocker.ps1 | iex"
```

* **Логи работы**: `%LocalAppData%\StellarisDLCUnlocker\unlocker.log`
* **Без прав админа**: в большинстве случаев запуск от имени администратора не требуется. Если что-то не работает — попробуйте запустить PowerShell от имени администратора и выполнить команду там.

#### Если что-то пошло не так
Переустановите игру через Steam, а затем **дополнительно вручную удалите** папку игры — Steam при удалении часто оставляет за собой остатки файлов, в том числе уже пропатченных. Обычно это: `C:\Program Files (x86)\Steam\steamapps\common\Stellaris`. После полного удаления установите игру заново и запустите анлокер. Решает подавляющее большинство проблем.

✅ Протестировано на Windows 10 и Windows 11.


## Linux

Игра на Linux может быть установлена в двух разных видах — нативная сборка (Steam Linux Runtime) либо Windows-сборка через Proton. Узнать, какая у вас, можно в свойствах игры в Steam → вкладка **Compatibility**. Если там включена принудительная версия Proton — у вас Windows-сборка, используйте анлокер для Proton. Если нет — у вас нативная сборка, используйте обычный Linux-анлокер.

### 🐧 Нативная сборка (CreamLinux)
Работает через [CreamLinux](https://github.com/anticitizn/creamlinux). Запускается одной командой, без скачивания файлов вручную:

```bash
curl -fsSL https://raw.githubusercontent.com/seuyh/stellaris-dlc-unlocker/main/StellarisDLCUnlocker.sh | bash
```

* **Логи работы**: `~/.local/share/StellarisDLCUnlocker/unlocker.log`
* Скрипт сам определяет установку Steam (нативная, Flatpak, Snap) и прописывает нужные параметры запуска игры
* Зависимости: `curl`, `unzip`, `grep`, `awk` (обычно уже есть в системе); рекомендуется `jq`

#### Если что-то пошло не так
Убедитесь, что у игры в Steam выставлен правильный параметр запуска. Проверить: правой кнопкой по Stellaris в библиотеке Steam → **Свойства** → вкладка **General** → поле **LAUNCH OPTIONS**. Там должно быть ровно:
```
sh ./cream.sh %command%
```
Если поле пустое или там что-то другое — впишите строку вручную и перезапустите игру.

✅ Протестировано на Zorin OS 18.1.

### 🍷 Версия через Proton
Работает через CreamAPI (Windows-эмулятор), запускаемый внутри вашего Proton-окружения. Тоже запускается одной командой, своим отдельным скриптом:

```bash
curl -fsSL https://raw.githubusercontent.com/seuyh/stellaris-dlc-unlocker/main/StellarisDLCUnlockerProton.sh | bash
```

* **Логи работы**: `~/.local/share/StellarisDLCUnlocker/unlocker.log`
* Скрипт сам находит Proton-префикс игры и устанавливает файлы прямо в него
* Зависимости те же, плюс используется `wine`/`Proton` из вашей установки Steam (отдельно ставить не нужно)

#### Если что-то пошло не так
Убедитесь, что параметр запуска у игры в Steam **пустой** — этой версии он не нужен, файлы подменяются напрямую. Проверить: правой кнопкой по Stellaris в библиотеке Steam → **Свойства** → вкладка **General** → поле **LAUNCH OPTIONS**. Если там что-то есть — очистите поле полностью.

✅ Протестировано на Zorin OS 18.1 с Proton 10.0-4.

### macOS и Steam Deck

**macOS не поддерживается.** Пути Steam, файловые механизмы (`LD_PRELOAD`/`.so` на Linux против `DYLD_INSERT_LIBRARIES`/Mach-O на macOS) и даже базовые утилиты (на macOS по умолчанию BSD-версии `sed`, а не GNU) отличаются настолько, что текущие скрипты на macOS просто не запустятся — потребовалась бы отдельная версия под платформу.

**Steam Deck — должно работать, но не тестировалось.** SteamOS — это Arch-based Linux, Stellaris на Deck по умолчанию идёт как Proton-игра, так что в теории подойдёт Proton-версия анлокера через Desktop Mode (терминал Konsole). Возможный нюанс: `jq` и `unzip` могут отсутствовать из коробки и потребуют установки. Если запускали на Deck — поделитесь результатом в issues.

### Заработает ли на других дистрибутивах?
Скорее всего да. Скрипты написаны на чистом bash и используют только стандартные утилиты (`curl`, `unzip`, `grep`, `awk`), которые есть практически в любом дистрибутиве, плюс штатные пути установки Steam (нативный пакет, Flatpak, Snap) определяются автоматически — а если автодетект не сработает, скрипт попросит указать путь вручную и проверит его на валидность. Глубоко тестировалось только на Zorin OS 18.1, но принципиальных причин не работать на Ubuntu, Fedora, Arch, Mint и подобных дистрибутивах нет. Если столкнётесь с проблемой на своём дистрибутиве — пишите в issues, поможем разобраться.


## Требования

- Лицензия Steam: Stellaris
- Windows 10/11 или Linux
- ~2 ГБ свободного места на диске
- Доступ к интернету


## Контакты

Телеграм канал [https://t.me/stelka_unlocker](https://t.me/stelka_unlocker)


## Лицензия

Этот проект лицензирован в соответствии с [Creative Commons Attribution-NonCommercial-NoDerivatives (CC BY-NC-ND) License](https://creativecommons.org/licenses/by-nc-nd/4.0/).


## Ошибки и предложения прошу писать сюда

https://github.com/seuyh/stellaris-dlc-unlocker/issues


## Отдельная благодарность

Автору темы посвященную ручной разблокировке DLC на [PLAYGROUND](https://www.playground.ru/stellaris/cheat/stellaris_dlc_unlocker_razblokirovschik_dopolnenij_3_10-1088979#29894040).

Перевод на Простой Китайский язык: [wuyilingwei](https://github.com/wuyilingwei).

Linux-версия реализована на основе [CreamLinux](https://github.com/anticitizn/creamlinux).

---

*Примечание: Анлокер находится на стадии разработки и предоставляется в формате "AS IS". В последствии продукт может изменяться, дополняться, улучшаться. Не исключено наличие багов, недочетов, вылетов.*
