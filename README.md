<p align="center">
  <img src="Assets/icon.png" alt="Aritlok UI" width="160">
</p>

<h1 align="center">Aritlok UI</h1>

<p align="center">
  A dark, flat interface overhaul for <b>World of Warcraft: Forever</b>, built on EllesmereUI.
</p>

<p align="center">
  <a href="https://www.curseforge.com/wow/addons/aritlokui"><b>Download on CurseForge</b></a>
</p>

<!-- Add a gameplay screenshot here once you have one you like:
![Gameplay](Assets/gameplay.png)
-->

## Features

- **Gradient unit frames** – class-coloured bars that run from a deep left end to a bright right end, on health, power and cast bars
- **Two themes** – Gradient (default) and Dark
- **Clean centre layout** – player and target frames either side of a free centre, with the power bar and cooldown manager in between
- **Compact action bars** – three rows at the bottom centre, two side blocks, and a mouse-over bar next to chat
- **Menu bar** – a slim strip along the bottom edge with a fading backdrop: micro menu, experience, durability, clock, professions, gold and performance
- **Tidy screen edges** – chat bottom left; minimap, quest tracker, tooltip and damage / healing meters down the right
- **Step-by-step installer** – five pages, every part optional
- **Pixel-perfect scale** – one UI unit per screen pixel (0.5333 at 2560 × 1440)
- **Monaspace Neon** font, with Argon bundled as an alternative
- **Non-destructive** – your EllesmereUI profile is copied, never overwritten

## Requirements

### Required AddOns

- [EllesmereUI](https://github.com/EllesmereGaming/EllesmereUI)

Aritlok UI styles and arranges these EllesmereUI modules, so keep them enabled:

| Module | Used for |
| --- | --- |
| Unit Frames | player, target, pet, target-of-target, focus |
| Action Bars | bars 1–6, stance and pet bars |
| DataBars | the menu bar |
| Cooldown Manager | the rows between the player and target frames |
| Chat | chat position, size and fonts |
| Damage Meters | damage and healing windows |
| Quest Tracker | tracker position and size |
| Minimap | minimap position |

A module that is switched off is simply skipped by the installer.

### Game version

World of Warcraft: Forever, interface `16001`.

## Installation

- Make a backup of your `WTF` folder
- Install EllesmereUI and log in once with it enabled
- Install Aritlok UI from [CurseForge](https://www.curseforge.com/wow/addons/aritlokui), or put this folder into `World of Warcraft/_forever_/Interface/AddOns/` and make sure it is named `AritlokUI` (the name has to match `AritlokUI.toc`)
- Restart the game client (a new addon folder is not picked up by `/reload`)
- Type `/aui install` and follow the five steps
- Click **Reload UI** on the last page

The installer copies your active EllesmereUI profile to a new one named `AritlokUI` and writes its settings there. To go back, type `/aui restore`.

## Commands

| Command | What it does |
| --- | --- |
| `/aui` | open the settings page inside the EllesmereUI panel |
| `/aui install` | open the step-by-step installer |
| `/aui apply [gradient\|dark]` | apply the theme straight away, without the installer window |
| `/aui restore` | switch EllesmereUI back to the profile and UI scale you had before |
| `/aui shade on\|off\|<0-90>` | bar gradients, and how deep the left end gets |
| `/aui bar on\|off\|top\|bottom` | the menu bar |
| `/aui xp <length> [offset]` | length of the experience bar on the menu bar, and where it starts |
| `/aui status` | what is switched on |
| `/aui probe` | print which client and EllesmereUI functions this build has |
| `/aui help` | list the commands |

`/aritlokui` works as an alias for `/aui`.

## What it does not do

- It does not read the combat log.
- It does not automate any combat decision.
- It does not replace Blizzard's unit frames, damage meter or cooldown manager itself; it arranges what EllesmereUI provides.
- It compiles no secure snippets and writes no attributes onto Blizzard frames.

## Known limits

- Bundled layout values are tuned on a 2560 × 1440 screen. Everything is scaled to your screen height, but other aspect ratios are less tested.
- Unit names are not gradient-coloured: that would mean altering the name text, which this addon never touches.
- The menu bar is built through an internal EllesmereUI table. If an EllesmereUI update changes it, the installer falls back to Aritlok UI's own simpler bar.
- Action buttons are 36 × 29 rather than a flatter shape, because that is the flattest EllesmereUI draws without stretching the icons.

## Development

This repository is the addon folder itself. To work on it, either clone it straight into your AddOns directory as `AritlokUI`, or keep it elsewhere and link it in.

### Clone into AddOns

```
cd "World of Warcraft/_forever_/Interface/AddOns"
git clone <repository url> AritlokUI
```

### Windows link

Open Command Prompt **as administrator**:

```
mklink /J "D:\Games\World of Warcraft\_forever_\Interface\AddOns\AritlokUI" "C:\path\to\AritlokUI"
```

Changes to existing files load with `/reload`. New files, and changes to the `.toc`, need a full client restart.

### Checks and releases

Every push to `main` and every pull request runs the **Test** workflow: a StyLua formatting check (run `stylua .` before committing), luacheck, plus checks that each Lua file starts with the namespace line, that nothing forbidden is used (combat log, secure snippets), and that the TOC matches the files.

Releases are made by pushing a tag from `main`:

| Tag | Result |
| --- | --- |
| `v0.2.0-beta.1` | beta file |
| `v0.2.0` | stable file (the tag must match `## Version:` in the TOC) |

Before tagging, update `## Version:` in `AritlokUI.toc`, `ns.VERSION` in `Core/Core.lua`, and `CHANGELOG.md`.

### Layout of the addon

| Path | Purpose |
| --- | --- |
| `AritlokUI.toc` | load order and metadata (has to stay in the root) |
| `Core/Core.lua` | namespace, saved variables, the single event frame, combat queue, probe |
| `Core/Media.lua` | textures, fonts, colour and gradient helpers |
| `Modules/Shade.lua` | gradient overlays on EllesmereUI's unit frame bars |
| `Modules/MicroBar.lua` | menu buttons for the built-in bar |
| `Modules/InfoBar.lua` | the menu bar backdrop, the built-in bar, the long XP bar |
| `Modules/Installer.lua` | everything the installer writes into the EllesmereUI profile |
| `Modules/Wizard.lua` | the installer window |
| `Modules/Options.lua` | settings page, slash command, addon compartment entry |
| `Media/` | textures and fonts used in game |
| `Assets/` | images for this README (left out of releases) |
| `.pkgmeta` | what a release contains |
| `CHANGELOG.md` | shown on CurseForge with each release |

## Credits

- **Ellesmere** for [EllesmereUI](https://github.com/EllesmereGaming/EllesmereUI), which Aritlok UI is built on
- **Toxi** and the [ToxiUI](https://github.com/Toxicom/toxiui) contributors, whose layout this one is modelled on
- **Smokenoaken** for [OakUI](https://github.com/Smokenoaken/OakUI_Installer), the reference for the menu bar
- **GitHub Next** for the [Monaspace](https://github.com/githubnext/monaspace) typeface

## Licences

- The Monaspace fonts in `Media/Fonts` are © GitHub and distributed unmodified under the SIL Open Font License 1.1. The licence text is in `Media/Fonts/Monaspace-LICENSE.txt`.
- No licence has been chosen yet for the addon's own code and artwork.
