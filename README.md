# Tunnel Escape: Fates Entwined — Trainer V6.6

**Free, fan-made offline trainer for Windows 10/11 (64-bit).**

Control nine cheats from a separate desktop window with HD icons, customizable multipliers, and a **PLAY (JOGAR)** button. Version 6.6 removes the old in-game **F8** cheat menu: all settings are managed through the external trainer.

> **Unofficial project.** This trainer is not affiliated with, sponsored by, or endorsed by the game's developers or publishers. The game itself is **not included**. Intended for offline/single-player use only.

> **Publication status (October 21, 2026):** English documentation is online. The full source assets and the v6.6 binary release are still pending upload. The download steps below apply once the release assets have been published.

<!-- The preview image will be enabled when docs/icons_preview.png is uploaded. -->

## Features

| # | Cheat | Description |
|---|---|---|
| 1 | Infinite Yen | Keeps your in-game money topped up. |
| 2 | Increased Drops | Customize item drop chance and quantity. |
| 3 | Faster ATB | Adjust combat/attack gauge speed. |
| 4 | XP Multiplier | Increase experience earned. |
| 5 | Extra PERKs | Adjust PERKs awarded per level. |
| 6 | Global Damage Multiplier | Increase overall damage. |
| 7 | Pistol Damage Multiplier | Adjust pistol damage. |
| 8 | Machine Gun Damage Multiplier | Adjust machine gun damage. |
| 9 | Reload Speed Multiplier | Customize reload speed. |

Other features: an HD Windows interface, animated header, game launcher, status display, local game bridge, and backups of modified plugin files.

## Download

1. Open the **[Releases](../../releases)** page.
2. Download **`TUNNEL_ESCAPE_FE_TRAINER_V6_6_SEM_F8.exe`** from the latest release. Alternatively, download **`TUNNEL_ESCAPE_FE_TRAINER_V6_6_SEM_F8_WINDOWS.zip`** and extract it.
3. Keep the trainer executable anywhere you like, such as your Desktop or a dedicated `Trainers` folder.

You need your own installed copy of **Tunnel Escape: Fates Entwined**. No separate plugin download is needed; the trainer carries its own resources.

## Installation (first-time users)

1. **Close the game completely** before installing or updating the bridge.
2. Launch **`TUNNEL_ESCAPE_FE_TRAINER_V6_6_SEM_F8.exe`**.
3. Click **`LOCALIZAR JOGO`** (*Locate Game*).
4. Select your game's main folder or the **`www`** folder. The trainer looks for `index.html`, `js/plugins.js`, and `js/rmmz_objects.js`.
5. With the game still closed, click **`INSTALAR PONTE`** (*Install Bridge*) and confirm.
6. Wait for the installation confirmation.
7. Click **`JOGAR`** (*Play*) to start the game. If asked, select the game's executable, typically `Game.exe` or `Tunnel Escape.exe`.
8. Once the status shows **`CONECTADO`** (*Connected*), switch cheats on/off and adjust multipliers in the trainer window.

**Important:** Installing a newer trainer EXE alone does not update the game plugin. To apply V6.6's removal of the internal F8 menu, close the game and press **`INSTALAR PONTE`** again.

## How to use

- Use the nine on/off buttons to enable or disable cheats.
- Use the sliders and +/- controls to set multipliers.
- With the **trainer window focused**, press **Ctrl + Alt + F1** through **Ctrl + Alt + F9** to toggle cheats 1–9.
- Keep the external trainer open while playing so you can adjust settings.
- **F8 does not open an in-game trainer menu in V6.6.**

## Updating from an older version

1. Close the game and any older trainer window.
2. Download and open V6.6.
3. Locate the game folder if it is not already selected.
4. Click **`INSTALAR PONTE`** while the game is closed.
5. Launch the game with **`JOGAR`**.

## Uninstall / restore game files

1. Close the game.
2. Launch the trainer and select the same game folder.
3. Click **`RESTAURAR PONTE`** (*Restore Bridge*).
4. Confirm and restart the game.

The trainer keeps backups of the original/previous plugin files when available. **Restoring may bring back the previous in-game F8 panel** if it was part of your earlier installation. Your save files are not intentionally modified by bridge installation or restoration; backing up important saves beforehand is still recommended.

## Troubleshooting

**The trainer says “SEM PASTA” (No Folder):** Click `LOCALIZAR JOGO` and select the correct game directory. Check for `index.html`, `js/plugins.js`, and `js/rmmz_objects.js` (sometimes inside `www`).

**The trainer says “AGUARDANDO JOGO” (Waiting for Game):** Check that the game is running, that the correct folder is selected, and that `INSTALAR PONTE` was completed with the game closed. Restart both programs if needed.

**The internal F8 menu still appears:** Close the game and click `INSTALAR PONTE` in V6.6 once more, then restart it.

**The PLAY button cannot find the game:** Select the game's `.exe` when prompted.

**Windows displays a security warning:** This is an independently built executable. Download only from a release you trust; verify the file hash and scan it with your security software. Do not disable security protections to run an untrusted file.

## Source code

The complete source package is being prepared for upload. The desktop launcher is built with Go and starts a local PowerShell/Windows Forms interface. The in-game integration uses JavaScript plugin files for the RPG Maker MZ game. These components operate on local files and do not require an online service.

To compile the Windows executable from an appropriate Go build environment, see `main.go`, `go.mod`, and the included icon resource. The compiled release is recommended for ordinary users.

## Notes

- **Platform:** Windows 10 / 11, x64.
- **Mode:** Offline / single player.
- **Current version:** v6.6 (no internal F8 menu).
- **Game:** Not bundled; users must obtain their own copy.
- **Backups:** Created for affected plugin files when the bridge is installed.
- **Security:** Use only trusted downloads; third-party trainers may be flagged by antivirus tools.

**Disclaimer:** Use at your own risk. Back up your game files and saves, and respect the game creators' rights and terms. No game files or commercial game license are provided by this project.