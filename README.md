# Stellaris DLC Unlocker

![Stellaris DLC Unlocker Logo](https://github.com/seuyh/stellaris-dlc-unlocker/blob/main/.banner/readme_banner.png)

| [Русский](README.md) | [English](README_EN.md) | [中文](README_ZHCN.md) |

---

## Описание

Утилита для автоматической разблокировки и установки DLC для игры Stellaris (Steam версия).


## Как использовать

## Способ 1 - 🚀 Быстрый запуск (PowerShell)
Самый простой способ запустить анлокер — выполнить команду в терминале (PowerShell) либо нажать сочетание клавиш win+r и вставить код в открывшееся окно:

```powershell
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/seuyh/stellaris-dlc-unlocker/refs/heads/main/StellarisDLCUnlocker.ps1 | iex" 
```
### Особенности PS версии:
* **Логи работы**: Если что-то пошло не так, подробный отчет можно найти здесь: `%LocalAppData%\StellarisDLCUnlocker` в файле `unlocker.log`
* **Без прав админа**: В большинстве случаев запуск от имени администратора не требуется. Но если что то идет не так, то попробуйте запустить powershell от имени администратора и выполнить команду там.

## Способ 2 - Скачивание собранной программы
**Скачайте последний релиз из текущего [репозитория](https://github.com/seuyh/stellaris-dlc-unlocker/releases).**

## Способ 3 - 🐍 Запуск через Python
1.  **Установите Python**: Убедитесь, что у вас установлен Python 3.8 или выше.
2.  **Скачайте репозиторий**: Клонируйте или скачайте архив с кодом.
3.  **Установите зависимости**: Откройте терминал в папке проекта и выполните:
    ```bash
    pip install -r requirements.txt
    ```
4.  **Запустите программу**:
    ```bash
    python main.py
    ```


## Требования

- Лицензия Steam: Stellaris
- Операционная система: Windows 10/11
- Доступ к интернету
- Примерно 2Гб свободного дискового пространства
- Умение читать текст на экране



## Контакты

Телеграм канал [https://t.me/stelka_unlocker](https://t.me/stelka_unlocker)

## По поводу детектов антивирусного ПО

Проблема кроется в работе pyinstaller которым был собран данный код, если вы переживаете за сохранность своего железа, то всегда можете использовать способ с PowerShell либо самостоятельно запустить код через Python, предварительно прочитав все исходники, либо не использовать данное ПО вообще. Пожалуйста не нужно создавать issue и писать об этом.
  

## Лицензия

Этот проект лицензирован в соответствии с [Creative Commons Attribution-NonCommercial-NoDerivatives (CC BY-NC-ND) License](https://creativecommons.org/licenses/by-nc-nd/4.0/).

## Ошибки и предложения прошу писать сюда

https://github.com/seuyh/stellaris-dlc-unlocker/issues


## Отдельная благодарность

Автору темы посвященную ручной разблокировке DLC на [PLAYGROUND](https://www.playground.ru/stellaris/cheat/stellaris_dlc_unlocker_razblokirovschik_dopolnenij_3_10-1088979#29894040).

Перевод на Простой Китайский язык: [wuyilingwei](https://github.com/wuyilingwei).

--- 

*Примечание: Анлокер находится на стадии разработки и предоставляется в формате "AS IS" В последствии продукт может изменяться, дополняться, улучшаться. Не исключено наличие багов, недочетов, вылетов.*
