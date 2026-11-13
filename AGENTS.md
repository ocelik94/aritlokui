# AGENTS.md

Guidance for AI coding agents working on AritlokUI. Read this before changing anything.

## What this is

AritlokUI is an addon for **World of Warcraft: Forever**. It does not draw its own unit frames or action bars. It sits on top of **EllesmereUI** and does two things:

1. **Installs a look.** A step-by-step installer copies the active EllesmereUI profile and writes settings into the copy (layout, fonts, colors, visibility).
2. **Adds what EllesmereUI cannot do.** Gradient overlays on unit frame bars, and a fading backdrop plus a long experience bar behind the menu bar.

The repository root **is** the addon folder. It is installed as `Interface/AddOns/AritlokUI`; the folder name has to match `AritlokUI.toc`.

## The client: read this first

Forever is **not** Classic Era and **not** a private server. It is its own game type in the Mainline family: the modern (12.x) UI engine with vanilla content. Assumptions from either Classic or Retail addons will be wrong in places.

- **TOC:** `## Interface: 16001`. Do not add Classic Era numbers (115xx).
- **Lua 5.1.** No `goto`, no `//`, no bitwise operators, no `_ENV`. There is no `require`, `dofile`, `loadfile`, `io` or `os`. Load order is the TOC; shared state lives on the addon namespace (`ns`).
- **Old globals are gone:** `GetSpellInfo`, `GetItemInfo`, `GetSpellBookItemName`, `GetNumTalentTabs`, `GetTalentInfo`, `GetNumSkillLines`. Use `C_Spell` and `C_Item`.
- **Project ID:** compare `WOW_PROJECT_ID` with `WOW_PROJECT_CAMELOT` when that constant exists, then check for the API the feature needs. See `ns.IsForever()` in `Core/Core.lua`.
- **Never trust an API from memory.** If you are not sure a function exists on Forever, add it to the probe (`ns.Probe` in `Core/Core.lua`) and say so. Do not invent `C_` functions.

### Hard rules

These are not style preferences. Breaking one produces errors or "Interface action failed because of an AddOn" in game.

- **No combat log.** Do not register `COMBAT_LOG_EVENT_UNFILTERED` or call `CombatLogGetCurrentEventInfo`. No damage meter, healing meter or combat-log boss mod.
- **Secret values.** Unit health, power and names can be *secret*: `type()` reports a normal type, but any arithmetic, comparison, concatenation or truth test throws. Guard with `ns.IsSecret(value)` before branching on or printing unit data. Pass health and max health straight into `StatusBar:SetMinMaxValues` / `SetValue`. **Do no arithmetic on health, power or names at all.**
- **No secure snippets.** No `SecureHandler*` templates with snippets, no `WrapScript`, no `RegisterStateDriver`, no `_onstate-*` attributes.
- **No attributes on Blizzard frames**, and do not replace Blizzard's unit frames, damage meter or cooldown manager.
- **Forbidden calls:** `ChatFrame_OpenChat`, `ChatEdit_ActivateChat`, `C_SuperTrack.SetSuperTrackedUserWaypoint`.
- **`pcall` does not make a protected call safe.** It only contains ordinary Lua errors.
- **Protected frames only outside combat.** Showing, hiding or moving one goes through `ns.RunOutOfCombat(fn)`, which queues until `PLAYER_REGEN_ENABLED`.
- **Reloading:** addon code may call `ReloadUI()` only from a click or key press, and only as the **first** thing that click does. Never reload from an event or timer.
- **Skin and inform.** Do not automate combat decisions.

## Code conventions

- **Every Lua file starts with exactly** `local addonName, ns = ...` (CI checks this).
- **SavedVariables** (`AritlokUIDB`) are read and created only inside `ADDON_LOADED` for this addon, merged onto `ns.defaults`. Never at file scope. A change to the shape of saved data needs a `schema` bump and a migration block in `Core/Core.lua`.
- **Events:** one frame, one handler table keyed by event name. Register with `ns.On(event, fn)`. Do not create more event frames and do not grow `if/elseif` chains on event names. `ns.On` returns `false` for an event the client does not have.
- **No `OnUpdate` polling** when an event exists.
- **Chat output** goes through `ns.Print`, which is safe to hand a secret value.
- **Formatting:** StyLua 2.6.0 with `.stylua.toml` (4 spaces, double quotes, 140 columns). Run `stylua .` before finishing; CI runs `stylua --check .`.
- **Comments** explain why something is the way it is on this client, especially where a rule above is the reason. Keep them when you move code.

## Layout of the repository

| Path | Purpose |
| --- | --- |
| `AritlokUI.toc` | load order and metadata (has to stay in the root) |
| `Core/Core.lua` | namespace, secret-value guards, saved variables, events, combat queue, probe |
| `Core/Changelog.lua` | release notes for the in-game Changelog page (English only, mirrors `CHANGELOG.md`) |
| `Core/Locale.lua` | the translation table `ns.L` |
| `Core/Media.lua` | textures, fonts, color and gradient helpers |
| `Locales/` | `deDE.lua`, `frFR.lua` |
| `Modules/Shade.lua` | gradient overlays on EllesmereUI's unit frame bars |
| `Modules/InfoBar.lua` | menu bar backdrop and the long experience bar |
| `Modules/RestedXP.lua` | theme registered with RestedXP Guides (through its own theme list) |
| `Modules/Professions.lua` | right-click on the menu bar's profession buttons (First Aid, Cooking) |
| `Modules/AFK.lua` | AFK screen (UIParent alpha, a frame on WorldFrame, camera turn) |
| `Modules/Tour.lua` | first-run tour (highlights placed at a target's screen position, never anchored to it) |
| `Modules/Options.lua` | settings page, `/aui` command, addon compartment entry |
| `Modules/Installer/Core.lua` | option list, profile choice, screen geometry, `ns.Install` |
| `Modules/Installer/*.lua` | one installer step per file (see below); `GroupFrames.lua` styles party/raid frames and nameplates and places them for the healer layout |
| `Modules/Installer/Wizard.lua` | the installer window |
| `Media/` | textures (`.tga`) and fonts used in game |
| `scripts/` | repository checks (`check.py`); excluded from releases |
| `Assets/` | the README icon; excluded from releases |
| `.previews/` | screenshots for the README and the WowUp Hub, which reads this folder from the tagged commit; excluded from releases |

A new Lua file has to be listed in `AritlokUI.toc` (backslashes in paths). CI fails if the TOC and the files on disk disagree.

## The installer

`ns.Install` runs registered **steps** in `order`. Each file under `Modules/Installer` registers its own:

```lua
I.AddStep({
    order = 110,
    option = "actionBars", -- key in AritlokUIDB.install, or nil to always run
    run = function(ctx)
        -- ctx.eui, ctx.db, ctx.want, ctx.theme, ctx.profile, ctx.addons
        -- ctx:Geometry() -> layout numbers for this screen
        -- ctx:Done("label"), ctx:Skip("reason")  (English; translated when recorded)
    end,
})
```

Things to know before touching it:

- **It writes EllesmereUI's saved settings.** Every key was read from EllesmereUI's source at the version in `I.TESTED_EUI`. EllesmereUI is not in this repository. **Do not guess a setting key**: find it in the installed EllesmereUI source and note where it came from. A wrong key is silently ignored.
- **It never writes into a profile it did not make.** `I.CheckProfileName` enforces that. Keep it that way.
- **Order matters.** Style, font, accent and UI scale run before the layout steps, because the scale decides the screen size the layout is computed for.
- **Layout numbers** come from `ctx:Geometry()`. They are based on a 1440-unit-tall reference layout and scaled by screen height; use `g.S(value)` for sizes and `g.Y(fromBottom)` for vertical positions rather than hard-coded pixels.
- **Nothing in the installer reloads.** The window ends on a button whose click only calls `ReloadUI()`.
- **Options are declared once.** `I.options`, `I.combatOptions` and `I.addons` feed both the installer window and the settings page. Add an option to the list, not to the two places that show it.

## Text and translations

- English text is written in the code and is the lookup key: `ns.L["English text"]`. Use **US spelling**.
- Text with changing parts uses `string.format` placeholders (`%s`, `%d`). A translation must keep them in the same order.
- **Every new visible string needs a line in both `Locales/deDE.lua` and `Locales/frFR.lua`.** `scripts/check.py` fails on a string in the code that reads like text and has no translation.
- Strings stored in tables (option titles, step names) stay English there and are translated where they are shown.
- `/aui probe` output is diagnostic and stays in English on purpose.
- Keep installer text short: one opening paragraph per page, one line per option. German and French run longer than English, and labels are single-line.

## Checks

Run these before saying a change is done.

```bash
stylua --check .
python3 scripts/check.py
```

`scripts/check.py` (Python 3, standard library only) checks the first line of every Lua file, forbidden APIs, that the TOC lists exactly the Lua files on disk, that German and French translate the same strings with the same placeholders, that **every text string in the code has a translation**, and that the version agrees in the TOC, `Core/Core.lua`, `CHANGELOG.md` and `Core/Changelog.lua`. Strings that look like text but are not shown translated (font and addon names, probe output) are listed in `NOT_TEXT` at the top of the script. The **Test** workflow runs StyLua and this script.

**What no check can tell you:** whether the addon works. There is no way to run the game client from here. State plainly what was verified by tooling and what has not been seen in game, and ask for a screenshot or the output of `/aui probe` when a result depends on the client.

## Releases

- Version lives in four places that must agree: `## Version:` in the TOC, `ns.VERSION` in `Core/Core.lua`, the top entry of `CHANGELOG.md`, and the top entry of `Core/Changelog.lua` (the same notes for the in-game Changelog page; the client cannot read the Markdown file).
- Tags are pushed from `main`: `v0.2.0-beta.1` for a beta, `v0.2.0` for a stable release. The stable workflow refuses a tag that does not match the TOC version.
- `.pkgmeta` lists what is left out of a release. Add repository-only files there.

## Working agreements

- **Do not commit, tag or push unless asked.**
- **Do not add dependencies or libraries.** EllesmereUI embeds LibStub and LibSharedMedia; use those through it.
- **Do not hook or replace EllesmereUI's functions.** Fields starting with `_` on its tables are internal; the one this addon uses (`_ModuleNS`, for the menu bar) is checked at every step, and the menu bar is simply left out when it is missing. The single exception to "do not hook" is `Modules/Professions.lua`, which post-hooks the click of EllesmereUI's two profession buttons and clears their right-click attribute outside combat; do not add more.
- **Fonts and textures** have to be `.tga` / `.ttf` / `.otf` with power-of-two texture sizes, and anything bundled needs a license that allows it. The Monaspace license file sits next to the fonts.
- **Scope:** this addon targets Forever only. Do not add other game versions or TOC files.
