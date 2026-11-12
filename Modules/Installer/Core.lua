local addonName, ns = ...

-------------------------------------------------------------------------------
--  Installer core
--  Puts the Aritlok look onto EllesmereUI without touching the profile you
--  are using: it copies the active EllesmereUI profile to a new one (the
--  shared "AritlokUI" or a name you choose), switches to it, and changes
--  settings there.
--
--  This file holds the shared pieces: the list of options (used by both the
--  installer window and the settings page), small table helpers, the screen
--  geometry every layout step works from, and ns.Install, which runs the
--  steps the other files in this folder register.
--
--  Only EllesmereUI's own profile functions and saved settings are used.
--  Every setting key written by the steps was read out of the EllesmereUI
--  version named in TESTED_EUI; the installer warns when another version is
--  running.
--
--  Reload rule on Forever: addon code may reload only from inside a click or
--  key press, and only as the first thing that click does. So nothing here
--  reloads; the installer window ends on a button that does nothing else.
-------------------------------------------------------------------------------

local L = ns.L

local I = {}
ns.Installer = I

-- Name of the shared profile.
I.SHARED_PROFILE = "AritlokUI"

-- The EllesmereUI version the setting keys were read from.
I.TESTED_EUI = "9.8.4"

I.GAP = 6

-------------------------------------------------------------------------------
--  Options
--  One list, shown by the installer window (grouped into its pages) and by the
--  settings page. `key` is the field in AritlokUIDB.install.
-------------------------------------------------------------------------------
I.options = {
    { key = "unitFrames", group = "layout", title = "Unit frames", desc = "Player, target and cooldown rows." },
    { key = "actionBars", group = "layout", title = "Action bars", desc = "Bottom rows, side blocks, mouse-over bar." },
    { key = "dataBar", group = "layout", title = "Menu bar", desc = "Needs EllesmereUI DataBars." },
    { key = "chat", group = "layout", title = "Chat", desc = "Bottom left, smaller text." },
    { key = "rightSide", group = "layout", title = "Right edge", desc = "Minimap, quests, tooltip, meters." },
    { key = "style", group = "look", title = "Flat style", desc = "Replaces the bronze WoW Forever look." },
    { key = "font", group = "look", title = "Monaspace Neon font", desc = "Chat tabs keep a narrower font." },
    { key = "accent", group = "look", title = "Class-color accent", desc = "Colors quests, meters, chat and menu bar." },
    { key = "scale", group = "look", title = "Pixel-perfect scale", desc = "Sharper and slightly smaller." },
    { key = "bags", group = "look", title = "Compact bags", desc = "Compact view, opening as one bag." },
}

-------------------------------------------------------------------------------
--  Helpers for the step files
-------------------------------------------------------------------------------
-- parent[key] as a table, created when missing.
function I.Sub(parent, key)
    local t = parent[key]
    if type(t) ~= "table" then
        t = {}
        parent[key] = t
    end
    return t
end

-- EllesmereUI stores a position as a frame's center, offset from the screen
-- center in UIParent units.
function I.Center(x, y) return { point = "CENTER", relPoint = "CENTER", x = x, y = y } end

-- The fields EllesmereUI's "never" visibility mode sets on a bar.
function I.Hide(bar)
    bar.barVisibility = "never"
    bar.alwaysHidden = true
end

-- Installed EllesmereUI version, the tested one, and whether they match.
function I.EUIVersion()
    local eui = _G.EllesmereUI
    local current = type(eui) == "table" and eui.VERSION or nil
    if type(current) ~= "string" then current = nil end
    return current, I.TESTED_EUI, current == I.TESTED_EUI
end

-------------------------------------------------------------------------------
--  Profile choice
--  The installer writes to one EllesmereUI profile: either the shared one
--  ("AritlokUI") or one with a name the player picks. EllesmereUI keeps a
--  single active profile for the whole account, so this decides the name and
--  what gets copied, not which characters use it; profiles can be assigned
--  per specialization under /eui > Profiles.
-------------------------------------------------------------------------------
-- A starting name for an own profile: "AritlokUI - <class>". The class name
-- is unit data, so it is checked for secrecy before it is used.
function I.SuggestedProfileName()
    local className = UnitClass and UnitClass("player")
    if type(className) == "string" and not ns.IsSecret(className) and className ~= "" then return I.SHARED_PROFILE .. " - " .. className end
    return I.SHARED_PROFILE .. " 2"
end

-- The profile name the installer will use with the current settings.
function I.ProfileName()
    local choice = ns.db.profile
    if choice.mode ~= "own" then return I.SHARED_PROFILE end
    local name = strtrim(choice.name or "")
    if name == "" then name = I.SuggestedProfileName() end
    return name
end

-- Whether `name` can be used. An existing profile is only reused when this
-- addon made it, so a profile of your own is never written into.
function I.CheckProfileName(name)
    if type(name) ~= "string" or strtrim(name) == "" then return false, L["Enter a profile name."] end
    if #name > 40 then return false, L["The profile name is too long (40 characters at most)."] end
    if name == I.SHARED_PROFILE then return true end
    local profiles = _G.EllesmereUIDB and _G.EllesmereUIDB.profiles
    if type(profiles) == "table" and profiles[name] and not ns.db.createdProfiles[name] then
        return false, string.format(L['A profile named "%s" already exists and was not made by AritlokUI. Pick another name.'], name)
    end
    return true
end

-------------------------------------------------------------------------------
--  Steps
--  Each file in this folder registers what it does:
--    I.AddStep({ order = <number>, option = <key in I.options or nil>,
--                run = function(ctx) ... end })
--  run reports through ctx:Done("label") and ctx:Skip("reason").
-------------------------------------------------------------------------------
local steps = {}

function I.AddStep(step)
    steps[#steps + 1] = step
    table.sort(steps, function(a, b) return a.order < b.order end)
end

-------------------------------------------------------------------------------
--  Geometry
--  The layout numbers are ToxiUI's own default profile (its ElvUI movers,
--  action bar and unit frame tables), laid out for a screen 1440 units tall.
--  Everything is scaled by this screen's height / 1440, so the proportions
--  hold on any resolution or UI scale.
--
--   [pet] NAME      100                              42      NAME [tot]
--         [=== player ===]    --- power bar ---    [=== target ===]
--         Lv        12.3K     (cooldown manager)   12.3K        Lv
--         [castbar]                                [castbar]
--         [pet bar]
--                              [stance]
--               +------+ [ Bar 1: 12 x 1 ] +------+
--   [chat][6]   | Bar4 | [ Bar 2: 12 x 1 ] | Bar5 |          [meters]
--   [chat][6]   | 4x3  | [ Bar 3: 12 x 1 ] | 4x3  |          [meters]
--   ======================= menu bar =======================
--
-- Only layout numbers (screen size, button size) go into the maths.
-------------------------------------------------------------------------------
-- scale: the UI scale just set by the scale step, if any. UIParent is 768
-- units tall at scale 1, so its height is known without reading it back.
local function Geometry(scale)
    local uiW, uiH = UIParent:GetSize()
    if scale then uiH = 768 / scale end
    if type(uiW) ~= "number" or type(uiH) ~= "number" or uiH <= 0 then return nil end
    if scale then uiW = uiH * (UIParent:GetWidth() / UIParent:GetHeight()) end
    local k = uiH / 1440
    local cfg = ns.db.bar
    local g = { k = k, uiW = uiW, uiH = uiH }

    -- A ToxiUI size, scaled and rounded to a whole unit.
    function g.S(v)
        local n = math.floor(v * k + 0.5)
        if n < 1 then n = 1 end
        return n
    end
    -- A ToxiUI "units up from the bottom of the screen", as a center offset.
    function g.Y(fromBottom) return (fromBottom - 720) * k end
    function g.X(v) return v * k end

    -- Height kept free at the bottom of the screen for the menu bar.
    g.reserved = (cfg.enabled and cfg.position ~= "TOP") and ns.InfoBarHeight() or 0

    -- Action buttons: 36 wide, 4 apart. ToxiUI's are 36 x 24, but EllesmereUI
    -- stretches the icon when width and height differ. Its "cropped" button
    -- shape is the undistorted way to get a wide, low button: a square button
    -- drawn at 80% height with the icon trimmed top and bottom to match. So
    -- the buttons come out 36 x 29 rather than 36 x 24.
    g.btnW, g.pad = g.S(36), g.S(4)
    g.btnH = g.btnW * 0.8
    g.step = g.btnH + g.pad
    g.rowW = 12 * g.btnW + 11 * g.pad
    -- Bar 1's bottom edge is 100 up; two more rows hang below it. Lift the
    -- whole stack if the lowest row would touch the menu bar.
    local lowest = 100 * k - 2 * g.step
    local need = g.reserved + I.GAP
    local lift = (lowest < need) and (need - lowest) or 0
    g.row1 = g.Y(100) + lift + g.btnH / 2

    -- Chat text area: bottom-left corner, clear of the menu bar. Shared by
    -- the chat step and the side bar placed next to it.
    g.chatX, g.chatY = 44, g.reserved + g.S(40)
    g.chatW, g.chatH = g.S(520), g.S(200)

    -- Unit frames: 300 x 36, centerd 390 left and right, bottom edge 420 up.
    g.frameW, g.frameH = g.S(300), g.S(36)
    g.frameX = g.X(390)
    g.frameY = g.Y(420) + g.frameH / 2
    return g
end

-------------------------------------------------------------------------------
--  Install
-------------------------------------------------------------------------------
local function Preflight()
    local eui = _G.EllesmereUI
    if type(eui) ~= "table" then return false, L["EllesmereUI is not loaded."] end
    if type(_G.EllesmereUIDB) ~= "table" or type(_G.EllesmereUIDB.profiles) ~= "table" then
        return false, L["EllesmereUI has no profile data yet. Log in once with it enabled, then try again."]
    end
    local needed = { "SaveCurrentAsProfile", "SwitchProfile", "GetActiveProfileName", "GetActiveProfileData" }
    for i = 1, #needed do
        if type(eui[needed[i]]) ~= "function" then
            return false, string.format(L["This EllesmereUI version has no %s(). Run /aui probe."], needed[i])
        end
    end
    if InCombatLockdown() then return false, L["You are in combat. Try again after the fight."] end
    return true
end

-- Returns true and a result table { done = {...}, skipped = {...} }, or false
-- and the reason.
function ns.Install(theme)
    local db = ns.db
    if theme ~= "dark" and theme ~= "gradient" then theme = db.theme end
    if theme ~= "dark" then theme = "gradient" end

    local ok, reason = Preflight()
    if not ok then
        ns.Print(string.format(L["cannot install: %s"], reason))
        return false, reason
    end

    local profileName = I.ProfileName()
    ok, reason = I.CheckProfileName(profileName)
    if not ok then
        ns.Print(string.format(L["cannot install: %s"], reason))
        return false, reason
    end

    local eui = _G.EllesmereUI
    if eui.GetActiveProfileName() ~= profileName then
        if _G.EllesmereUIDB.profiles[profileName] then
            eui.SwitchProfile(profileName)
        else
            eui.SaveCurrentAsProfile(profileName) -- copies the active profile, then switches
            db.createdProfiles[profileName] = true
        end
    end

    -- Never write into a profile other than our own copy.
    if eui.GetActiveProfileName() ~= profileName then
        reason = string.format(L["EllesmereUI did not switch to the %s profile. Nothing was changed."], profileName)
        ns.Print(string.format(L["cannot install: %s"], reason))
        return false, reason
    end
    local profile = eui.GetActiveProfileData()
    if type(profile) ~= "table" then
        reason = L["EllesmereUI returned no profile data. Nothing was changed."]
        ns.Print(string.format(L["cannot install: %s"], reason))
        return false, reason
    end

    local ctx = {
        eui = eui,
        db = db,
        want = db.install,
        theme = theme,
        profile = profile,
        profileName = profileName,
        addons = I.Sub(profile, "addons"),
        done = {},
        skipped = {},
        scale = nil, -- set by the scale step
        menuBar = false, -- set by the menu bar step when EllesmereUI's DataBar is in place
    }
    -- Both take an English label (translated here) and optional format values.
    function ctx:Done(label, ...) self.done[#self.done + 1] = string.format(L[label], ...) end
    function ctx:Skip(why, ...) self.skipped[#self.skipped + 1] = string.format(L[why], ...) end
    -- Worked out once, on first use, so it sees the scale and menu bar steps.
    function ctx:Geometry()
        if self.g == nil then self.g = Geometry(self.scale) or false end
        return self.g or nil
    end

    local current, tested, matches = I.EUIVersion()
    if not matches then
        ns.Print(
            string.format(
                L["note: written for EllesmereUI %s, you have %s. Some settings may not apply."],
                tested,
                ns.Text(current or L["an unknown version"])
            )
        )
    end

    for i = 1, #steps do
        local step = steps[i]
        if step.option == nil or ctx.want[step.option] then step.run(ctx) end
    end

    db.theme = theme
    db.installed = true
    ns.RefreshShades()
    ns.ApplyInfoBar()

    ns.Print(
        string.format(
            L['installed the %s theme into EllesmereUI profile "%s": %s.'],
            L[theme == "dark" and "Dark" or "Gradient"],
            profileName,
            #ctx.done > 0 and table.concat(ctx.done, ", ") or L["nothing"]
        )
    )
    if #ctx.skipped > 0 then ns.Print(string.format(L["skipped: %s."], table.concat(ctx.skipped, "; "))) end
    return true, { done = ctx.done, skipped = ctx.skipped, profile = profileName }
end
