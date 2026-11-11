local addonName, ns = ...

-------------------------------------------------------------------------------
--  Slash command, addon-compartment entry and the settings page inside the
--  EllesmereUI options panel (EllesmereUI.RegisterPlugin, its documented
--  plugin API).
-------------------------------------------------------------------------------

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
        ns.Print("the settings page needs EllesmereUI's plugin API. Use /aui help for the chat commands.")
        return
    end
    local ran = ns.RunOutOfCombat(function()
        if not eui.OpenPlugin(PLUGIN_ID) then
            ns.Print("EllesmereUI could not open the settings page. Use /aui help for the chat commands.")
        end
    end)
    if not ran then
        ns.Print("in combat: the settings page opens when the fight ends.")
    end
end

-- Named in the TOC as AddonCompartmentFunc.
function AritlokUI_OnAddonCompartmentClick()
    ns.OpenOptions()
end

-------------------------------------------------------------------------------
--  Settings page
-------------------------------------------------------------------------------
local function BuildThemePage(W, parent, y)
    local db = ns.db
    local prebuild = _G.EllesmereUI.IsSearchPrebuild and _G.EllesmereUI.IsSearchPrebuild()
    local _, h

    _, h = W:SectionHeader(parent, "THEME", y); y = y - h
    _, h = W:Dropdown(parent, "Theme", y,
        { gradient = "Gradient (class colours)", dark = "Dark" },
        function() return db.theme end,
        function(v) db.theme = v; Refresh() end,
        { "gradient", "dark" },
        "Used the next time you press Install. Dark switches EllesmereUI's unit frames to their dark theme."); y = y - h

    _, h = W:SectionHeader(parent, "BAR GRADIENTS", y); y = y - h
    _, h = W:Toggle(parent, "Gradient unit frame bars", y,
        function() return db.shade.enabled end,
        function(v) db.shade.enabled = v; Refresh() end,
        "Deepens the left end and brightens the right end of every EllesmereUI unit frame health, power and cast bar. Off in the Dark theme."); y = y - h
    _, h = W:Slider(parent, "Left end depth", y, 0, 90, 5,
        function() return db.shade.strength end,
        function(v) db.shade.strength = v; Refresh() end); y = y - h
    _, h = W:Slider(parent, "Right end glow", y, 0, 60, 5,
        function() return db.shade.glow end,
        function(v) db.shade.glow = v; Refresh() end); y = y - h

    _, h = W:SectionHeader(parent, "INSTALL INTO ELLESMEREUI", y); y = y - h
    _, h = W:Toggle(parent, "Unit frames", y,
        function() return db.install.unitFrames end,
        function(v) db.install.unitFrames = v end,
        "ToxiUI layout: 300 x 36 player and target either side of a free centre, texts above and below the bar, power bar in the middle."); y = y - h
    _, h = W:Toggle(parent, "Action bars", y,
        function() return db.install.actionBars end,
        function(v) db.install.actionBars = v end,
        "ToxiUI layout: wide 36 x 29 buttons with cropped icons, bars 1-3 stacked at the bottom centre, bars 4 and 5 as 4 x 3 blocks beside them, bar 6 as a mouse-over block right of chat (2 across, 6 down), bars 7-10 off unless you placed them."); y = y - h
    _, h = W:Toggle(parent, "Bottom bar from EllesmereUI DataBars", y,
        function() return db.install.dataBar end,
        function(v) db.install.dataBar = v end,
        "Builds the bottom bar with EllesmereUI's DataBars module (icon micro menu, clock, gold). Off uses the built-in bar."); y = y - h
    _, h = W:Toggle(parent, "Pixel-perfect UI scale", y,
        function() return db.install.scale end,
        function(v) db.install.scale = v end,
        "Sets EllesmereUI's UI scale to 768 / screen height: 0.5333 at 2560 x 1440."); y = y - h
    _, h = W:Toggle(parent, "Monaspace Neon font", y,
        function() return db.install.font end,
        function(v) db.install.font = v end,
        "Sets EllesmereUI's global font to Monaspace Neon (Regular). Other Neon and Argon weights are also in EllesmereUI's font list."); y = y - h
    _, h = W:Toggle(parent, "Accent colour", y,
        function() return db.install.accent end,
        function(v) db.install.accent = v end,
        "Sets EllesmereUI's accent, which colours the quest tracker, damage meter, chat and bottom bar alike."); y = y - h
    _, h = W:Toggle(parent, "Accent is my class colour", y,
        function() return db.install.accentClass end,
        function(v) db.install.accentClass = v end,
        "Off uses Aritlok blue instead."); y = y - h
    _, h = W:Toggle(parent, "Chat in the bottom-left corner", y,
        function() return db.install.chat end,
        function(v) db.install.chat = v end); y = y - h
    _, h = W:Toggle(parent, "Minimap in the top-right corner", y,
        function() return db.install.minimap end,
        function(v) db.install.minimap = v end); y = y - h
    _, h = W:Toggle(parent, "Quest tracker, tooltip and damage meter on the right edge", y,
        function() return db.install.rightSide end,
        function(v) db.install.rightSide = v end); y = y - h
    _, h = W:Toggle(parent, "Flat EllesmereUI style on every module", y,
        function() return db.install.style end,
        function(v) db.install.style = v end,
        "Replaces the bronze WoW Forever look with EllesmereUI's flat one."); y = y - h

    _, h = W:WideButton(parent, "Open the installer", y, function()
        if prebuild then return end
        ns.OpenInstaller()
    end); y = y - h
    _, h = W:WideButton(parent, "Apply now without the installer", y, function()
        if prebuild then return end
        ns.Install(db.theme)
    end); y = y - h
    _, h = W:WideButton(parent, "Switch back to my previous profile", y, function()
        if prebuild then return end
        ns.Restore()
    end); y = y - h

    return y
end

local function BuildBarPage(W, parent, y)
    local cfg = ns.db.bar
    local _, h

    _, h = W:SectionHeader(parent, "INFO BAR", y); y = y - h
    _, h = W:Toggle(parent, "Show the info bar", y,
        function() return cfg.enabled end,
        function(v) cfg.enabled = v; Refresh() end); y = y - h
    _, h = W:Dropdown(parent, "Position", y,
        { BOTTOM = "Bottom of the screen", TOP = "Top of the screen" },
        function() return cfg.position end,
        function(v) cfg.position = v; Refresh() end,
        { "BOTTOM", "TOP" }); y = y - h
    _, h = W:Slider(parent, "Height", y, 18, 48, 1,
        function() return cfg.height end,
        function(v) cfg.height = v; Refresh() end); y = y - h
    _, h = W:Slider(parent, "Background opacity", y, 0, 100, 5,
        function() return cfg.opacity end,
        function(v) cfg.opacity = v; Refresh() end); y = y - h
    _, h = W:Toggle(parent, "Class-colour wash", y,
        function() return cfg.classWash end,
        function(v) cfg.classWash = v; Refresh() end); y = y - h
    _, h = W:Toggle(parent, "Menu buttons (built-in bar)", y,
        function() return cfg.micro end,
        function(v) cfg.micro = v; Refresh() end,
        "Letter buttons for character, spellbook, talents and so on. The EllesmereUI DataBars bar has its own icon menu."); y = y - h
    _, h = W:Slider(parent, "XP bar length (menu bar)", y, 100, 800, 20,
        function() return cfg.xpLength end,
        function(v) cfg.xpLength = v; Refresh() end,
        "Length of the XP bar on the EllesmereUI bottom bar. Run the installer again afterwards so the bar leaves the same room."); y = y - h
    _, h = W:Slider(parent, "XP bar start (from the left edge)", y, 100, 800, 10,
        function() return cfg.xpOffset end,
        function(v) cfg.xpOffset = v; Refresh() end); y = y - h
    _, h = W:Toggle(parent, "Experience hairline", y,
        function() return cfg.showXP end,
        function(v) cfg.showXP = v; Refresh() end); y = y - h

    _, h = W:SectionHeader(parent, "CLOCK", y); y = y - h
    _, h = W:Toggle(parent, "24-hour clock", y,
        function() return cfg.clock24 end,
        function(v) cfg.clock24 = v; Refresh() end); y = y - h
    _, h = W:Toggle(parent, "Local time (off = realm time)", y,
        function() return cfg.localTime end,
        function(v) cfg.localTime = v; Refresh() end); y = y - h

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
                description = "Theme, health bar shade and info bar.",
                pages = { "Theme", "Info Bar" },
                buildPage = function(pageName, parent, yOffset)
                    local W = _G.EllesmereUI.Widgets
                    if not W or not ns.db then return 0 end
                    local y
                    if pageName == "Info Bar" then
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
    "/aui install              open the step-by-step installer",
    "/aui apply [gradient|dark]     theme the \"AritlokUI\" profile straight away, no window",
    "/aui restore              switch EllesmereUI back to the profile you had before",
    "/aui shade on|off|<0-90>  bar gradients and how deep the left end gets",
    "/aui bar on|off|top|bottom     info bar",
    "/aui xp <length> [offset] length of the XP bar on the menu bar, and where it starts",
    "/aui status               what is switched on",
    "/aui probe                print which client and EllesmereUI APIs this build has",
    "/aui help                 this list",
}

local function OnOff(v) return v and "on" or "off" end

local commands = {}

commands.help = function()
    ns.Print("version " .. ns.VERSION .. " commands:")
    for i = 1, #HELP do
        ns.Print(HELP[i])
    end
end

commands.config = function() ns.OpenOptions() end
commands.options = commands.config

commands.install = function() ns.OpenInstaller() end

commands.apply = function(arg)
    if arg ~= "" and arg ~= "gradient" and arg ~= "dark" then
        ns.Print("unknown theme \"" .. arg .. "\". Use gradient or dark.")
        return
    end
    ns.Install(arg ~= "" and arg or nil)
end

commands.restore = function() ns.Restore() end

commands.shade = function(arg)
    local db = ns.db
    local n = tonumber(arg)
    if arg == "on" then db.shade.enabled = true
    elseif arg == "off" then db.shade.enabled = false
    elseif n and n >= 0 and n <= 90 then db.shade.strength = n; db.shade.enabled = true
    else
        ns.Print("usage: /aui shade on|off|<0-90>")
        return
    end
    Refresh()
    ns.Print("shade " .. OnOff(db.shade.enabled) .. ", strength " .. db.shade.strength .. ".")
end

commands.bar = function(arg)
    local cfg = ns.db.bar
    if arg == "on" then cfg.enabled = true
    elseif arg == "off" then cfg.enabled = false
    elseif arg == "top" then cfg.position = "TOP"; cfg.enabled = true
    elseif arg == "bottom" then cfg.position = "BOTTOM"; cfg.enabled = true
    else
        ns.Print("usage: /aui bar on|off|top|bottom")
        return
    end
    Refresh()
    ns.Print("info bar " .. OnOff(cfg.enabled) .. ", " .. string.lower(cfg.position) .. ".")
end

commands.xp = function(arg)
    local cfg = ns.db.bar
    local length, offset = string.match(arg, "^(%d+)%s*(%d*)$")
    length = tonumber(length)
    if not length then
        ns.Print("usage: /aui xp <length> [offset from left]. Now " .. cfg.xpLength .. " long, starting at " .. cfg.xpOffset .. ".")
        return
    end
    cfg.xpLength = length
    if tonumber(offset) then cfg.xpOffset = tonumber(offset) end
    Refresh()
    ns.Print("XP bar " .. cfg.xpLength .. " long, starting at " .. cfg.xpOffset
        .. ". Run /aui install again so the menu bar leaves the same room for it.")
end

commands.status = function()
    local db = ns.db
    local eui = _G.EllesmereUI
    local profile = (type(eui) == "table" and eui.GetActiveProfileName) and eui.GetActiveProfileName() or "?"
    ns.Print("theme " .. db.theme .. ", installed " .. OnOff(db.installed)
        .. ", EllesmereUI profile \"" .. ns.Text(profile) .. "\".")
    ns.Print("shade " .. OnOff(db.shade.enabled) .. " (" .. db.shade.strength .. "), info bar "
        .. OnOff(db.bar.enabled) .. " (" .. string.lower(db.bar.position) .. ").")
end

commands.probe = function() ns.Probe() end

SLASH_ARITLOKUI1 = "/aui"
SLASH_ARITLOKUI2 = "/aritlokui"
SlashCmdList["ARITLOKUI"] = function(msg)
    if not ns.db then
        ns.Print("saved settings have not loaded yet.")
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
        ns.Print("unknown command \"" .. name .. "\".")
        handler = commands.help
        arg = ""
    end
    handler(arg)
end

ns.On("PLAYER_LOGIN", RegisterPlugin)
