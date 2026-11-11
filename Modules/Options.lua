local addonName, ns = ...

-------------------------------------------------------------------------------
--  Slash command, addon-compartment entry and the settings page inside the
--  EllesmereUI options panel (EllesmereUI.RegisterPlugin, its documented
--  plugin API).
-------------------------------------------------------------------------------

local L = ns.L

local PLUGIN_ID = "AritlokUI"

local function Refresh()
    ns.RefreshShades()
    ns.ApplyInfoBar()
end

-------------------------------------------------------------------------------
--  Opening the settings page. EllesmereUI's panel does not open in combat, so
--  the request waits in the combat queue.
-------------------------------------------------------------------------------
function ns.OpenOptions()
    local eui = _G.EllesmereUI
    if type(eui) ~= "table" or not eui.OpenPlugin then
        ns.Print(L["the settings page needs EllesmereUI's plugin API. Use /aui help for the chat commands."])
        return
    end
    local ran = ns.RunOutOfCombat(function()
        if not eui.OpenPlugin(PLUGIN_ID) then
            ns.Print(L["EllesmereUI could not open the settings page. Use /aui help for the chat commands."])
        end
    end)
    if not ran then ns.Print(L["in combat: the settings page opens when the fight ends."]) end
end

-- Named in the TOC as AddonCompartmentFunc.
function AritlokUI_OnAddonCompartmentClick() ns.OpenOptions() end

-------------------------------------------------------------------------------
--  Settings page
-------------------------------------------------------------------------------
-- EllesmereUI's widget factory, with every text argument translated on the
-- way in: labels, tooltips, and the display values of dropdowns. Keys (the
-- dropdown order lists, "gradient", "TOP" and so on) have no translation and
-- pass through unchanged.
local function Localized(W)
    return setmetatable({}, {
        __index = function(_, method)
            local fn = W[method]
            if type(fn) ~= "function" then return fn end
            return function(_, ...)
                local n = select("#", ...)
                local args = { ... }
                for i = 2, n do -- argument 1 is the parent frame
                    local a = args[i]
                    if type(a) == "string" then
                        args[i] = L[a]
                    elseif type(a) == "table" then
                        local copy = {}
                        for k, v in pairs(a) do
                            copy[k] = (type(v) == "string") and L[v] or v
                        end
                        args[i] = copy
                    end
                end
                return fn(W, unpack(args, 1, n))
            end
        end,
    })
end

local PAGE_THEME, PAGE_BAR = "Theme", "Menu Bar"

local function BuildThemePage(W, parent, y)
    local db = ns.db
    local prebuild = _G.EllesmereUI.IsSearchPrebuild and _G.EllesmereUI.IsSearchPrebuild()
    local _, h

    _, h = W:SectionHeader(parent, "THEME", y)
    y = y - h
    _, h = W:Dropdown(
        parent,
        "Theme",
        y,
        { gradient = "Gradient (class colors)", dark = "Dark" },
        function() return db.theme end,
        function(v)
            db.theme = v
            Refresh()
        end,
        { "gradient", "dark" },
        "Used the next time you run the installer. Dark switches EllesmereUI's unit frames to their dark theme."
    )
    y = y - h

    _, h = W:SectionHeader(parent, "BAR GRADIENTS", y)
    y = y - h
    _, h = W:Toggle(
        parent,
        "Gradient unit frame bars",
        y,
        function() return db.shade.enabled end,
        function(v)
            db.shade.enabled = v
            Refresh()
        end,
        "Deepens the left end and brightens the right end of every EllesmereUI unit frame health, power and cast bar. Off in the Dark theme."
    )
    y = y - h
    _, h = W:Slider(parent, "Left end depth", y, 0, 90, 5, function() return db.shade.strength end, function(v)
        db.shade.strength = v
        Refresh()
    end)
    y = y - h
    _, h = W:Slider(parent, "Right end glow", y, 0, 60, 2, function() return db.shade.glow end, function(v)
        db.shade.glow = v
        Refresh()
    end)
    y = y - h

    -- The same list the installer window shows.
    _, h = W:SectionHeader(parent, "WHAT THE INSTALLER APPLIES", y)
    y = y - h
    local options = ns.Installer.options
    for i = 1, #options do
        local option = options[i]
        _, h = W:Toggle(
            parent,
            option.title,
            y,
            function() return db.install[option.key] end,
            function(v) db.install[option.key] = v end,
            option.desc
        )
        y = y - h
    end

    _, h = W:SectionHeader(parent, "HIDDEN OUT OF COMBAT", y)
    y = y - h
    local combat = ns.Installer.combatOptions
    for i = 1, #combat do
        local option = combat[i]
        _, h = W:Toggle(
            parent,
            option.title,
            y,
            function() return db.install.combat[option.key] end,
            function(v) db.install.combat[option.key] = v end,
            option.desc
        )
        y = y - h
    end

    _, h = W:SectionHeader(parent, "OTHER ADDONS", y)
    y = y - h
    -- Integrations for other addons, when those addons are loaded.
    local found = ns.Installer.DetectedAddons()
    for i = 1, #found do
        local entry = found[i]
        _, h = W:Toggle(
            parent,
            entry.title,
            y,
            function() return db.install.addons[entry.key] end,
            function(v) db.install.addons[entry.key] = v end,
            entry.desc
        )
        y = y - h
    end

    _, h = W:WideButton(parent, "Open the installer", y, function()
        if prebuild then return end
        ns.OpenInstaller()
    end)
    y = y - h

    return y
end

local function BuildBarPage(W, parent, y)
    local cfg = ns.db.bar
    local _, h

    _, h = W:SectionHeader(parent, "BACKDROP", y)
    y = y - h
    _, h = W:Toggle(parent, "Show the backdrop and XP bar", y, function() return cfg.enabled end, function(v)
        cfg.enabled = v
        Refresh()
    end, "The fading strip behind the menu bar. The menu bar itself is an EllesmereUI DataBar.")
    y = y - h
    _, h = W:Dropdown(parent, "Screen edge", y, { BOTTOM = "Bottom", TOP = "Top" }, function() return cfg.position end, function(v)
        cfg.position = v
        Refresh()
    end, { "BOTTOM", "TOP" }, "Run the installer again afterwards so the menu bar and the layout move with it.")
    y = y - h
    _, h = W:Slider(parent, "Opacity", y, 0, 100, 5, function() return cfg.opacity end, function(v)
        cfg.opacity = v
        Refresh()
    end)
    y = y - h
    _, h = W:Toggle(parent, "Class-color wash", y, function() return cfg.classWash end, function(v)
        cfg.classWash = v
        Refresh()
    end)
    y = y - h

    _, h = W:SectionHeader(parent, "EXPERIENCE BAR", y)
    y = y - h
    _, h = W:Toggle(parent, "Long experience bar", y, function() return cfg.showXP end, function(v)
        cfg.showXP = v
        Refresh()
    end, "Replaces the DataBar's short XP block. Run the installer again after changing this.")
    y = y - h
    _, h = W:Slider(parent, "Length", y, 100, 800, 20, function() return cfg.xpLength end, function(v)
        cfg.xpLength = v
        Refresh()
    end, "Run the installer again afterwards so the menu bar leaves the same room.")
    y = y - h
    _, h = W:Slider(parent, "Start (from the left edge)", y, 100, 800, 10, function() return cfg.xpOffset end, function(v)
        cfg.xpOffset = v
        Refresh()
    end)
    y = y - h

    _, h = W:SectionHeader(parent, "CLOCK", y)
    y = y - h
    _, h = W:Toggle(
        parent,
        "24-hour clock",
        y,
        function() return cfg.clock24 end,
        function(v) cfg.clock24 = v end,
        "Applied the next time you run the installer."
    )
    y = y - h

    return y
end

local function RegisterPlugin()
    local eui = _G.EllesmereUI
    if type(eui) ~= "table" or not eui.RegisterPlugin then return end
    if eui.IsPluginRegistered and eui.IsPluginRegistered(PLUGIN_ID) then return end
    eui.RegisterPlugin(PLUGIN_ID, {
        label = "Aritlok UI",
        modules = {
            {
                key = "General",
                title = "Aritlok UI",
                description = L["Theme, bar gradients and the menu bar."],
                pages = { L[PAGE_THEME], L[PAGE_BAR] },
                buildPage = function(pageName, parent, yOffset)
                    local W = _G.EllesmereUI.Widgets
                    if not W or not ns.db then return 0 end
                    W = Localized(W)
                    local y
                    if pageName == L[PAGE_BAR] then
                        y = BuildBarPage(W, parent, yOffset)
                    else
                        y = BuildThemePage(W, parent, yOffset)
                    end
                    return math.abs(y)
                end,
                onReset = function()
                    local db = ns.db
                    db.theme = nil
                    db.shade = nil
                    db.bar = nil
                    db.install = nil
                    ns.MergeDefaults(db, ns.defaults)
                    Refresh()
                end,
            },
        },
    })
end

-------------------------------------------------------------------------------
--  /aui
-------------------------------------------------------------------------------
local HELP = {
    "/aui                      open the settings page (EllesmereUI panel)",
    "/aui install              open the installer",
    "/aui shade on|off|<0-90>  bar gradients and how deep the left end gets",
    "/aui bar on|off|top|bottom     the menu bar backdrop and XP bar",
    "/aui xp <length> [offset] length of the XP bar on the menu bar, and where it starts",
    "/aui status               what is switched on",
    "/aui probe                print which client and EllesmereUI functions this build has",
    "/aui help                 this list",
}

local function OnOff(v) return L[v and "on" or "off"] end

local commands = {}

commands.help = function()
    ns.Print(string.format(L["version %s commands:"], ns.VERSION))
    for i = 1, #HELP do
        ns.Print(L[HELP[i]])
    end
end

commands.config = function() ns.OpenOptions() end
commands.options = commands.config

commands.install = function() ns.OpenInstaller() end

commands.shade = function(arg)
    local db = ns.db
    local n = tonumber(arg)
    if arg == "on" then
        db.shade.enabled = true
    elseif arg == "off" then
        db.shade.enabled = false
    elseif n and n >= 0 and n <= 90 then
        db.shade.strength = n
        db.shade.enabled = true
    else
        ns.Print(L["usage: /aui shade on|off|<0-90>"])
        return
    end
    Refresh()
    ns.Print(string.format(L["gradients %s, depth %d."], OnOff(db.shade.enabled), db.shade.strength))
end

commands.bar = function(arg)
    local cfg = ns.db.bar
    if arg == "on" then
        cfg.enabled = true
    elseif arg == "off" then
        cfg.enabled = false
    elseif arg == "top" then
        cfg.position = "TOP"
        cfg.enabled = true
    elseif arg == "bottom" then
        cfg.position = "BOTTOM"
        cfg.enabled = true
    else
        ns.Print(L["usage: /aui bar on|off|top|bottom"])
        return
    end
    Refresh()
    ns.Print(
        string.format(
            L["backdrop %s, %s. Run /aui install to move the menu bar with it."],
            OnOff(cfg.enabled),
            L[cfg.position == "TOP" and "top" or "bottom"]
        )
    )
end

commands.xp = function(arg)
    local cfg = ns.db.bar
    local length, offset = string.match(arg, "^(%d+)%s*(%d*)$")
    length = tonumber(length)
    if not length then
        ns.Print(string.format(L["usage: /aui xp <length> [offset from left]. Now %d long, starting at %d."], cfg.xpLength, cfg.xpOffset))
        return
    end
    cfg.xpLength = length
    if tonumber(offset) then cfg.xpOffset = tonumber(offset) end
    Refresh()
    ns.Print(
        string.format(
            L["XP bar %d long, starting at %d. Run /aui install so the menu bar leaves the same room for it."],
            cfg.xpLength,
            cfg.xpOffset
        )
    )
end

commands.status = function()
    local db = ns.db
    local eui = _G.EllesmereUI
    local profile = (type(eui) == "table" and eui.GetActiveProfileName) and eui.GetActiveProfileName() or "?"
    local current, tested, matches = ns.Installer.EUIVersion()
    ns.Print(
        string.format(
            L['theme %s, installed %s, EllesmereUI profile "%s".'],
            L[db.theme == "dark" and "Dark" or "Gradient"],
            OnOff(db.installed),
            ns.Text(profile)
        )
    )
    ns.Print(string.format(L["gradients %s (%d), backdrop %s."], OnOff(db.shade.enabled), db.shade.strength, OnOff(db.bar.enabled)))
    if matches then
        ns.Print("EllesmereUI " .. ns.Text(current) .. " " .. L["(tested version)"])
    else
        ns.Print(string.format(L["EllesmereUI %s, tested with %s."], ns.Text(current or "?"), tested))
    end
end

commands.probe = function() ns.Probe() end

SLASH_ARITLOKUI1 = "/aui"
SLASH_ARITLOKUI2 = "/aritlokui"
SlashCmdList["ARITLOKUI"] = function(msg)
    if not ns.db then
        ns.Print(L["saved settings have not loaded yet."])
        return
    end
    msg = string.lower(strtrim(msg or ""))
    local name, arg = string.match(msg, "^(%S+)%s*(.-)$")
    if not name then
        ns.OpenOptions()
        return
    end
    local handler = commands[name]
    if not handler then
        ns.Print(string.format(L['unknown command "%s".'], name))
        handler = commands.help
        arg = ""
    end
    handler(arg)
end

ns.On("PLAYER_LOGIN", RegisterPlugin)
