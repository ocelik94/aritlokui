local addonName, ns = ...

-------------------------------------------------------------------------------
--  AritlokUI core: namespace, secret-value guards, saved variables, the single
--  event frame with its handler table, and the combat queue.
-------------------------------------------------------------------------------

ns.VERSION = "0.1.1"
ns.TAG = "|cff18a8ffAritlok|r|cffffffffUI|r"

-- Interface number this addon was written against. RETEST when the TOC number
-- moves: the login check at the bottom of this file and IsForever() below.
ns.EXPECTED_INTERFACE = 16001

-------------------------------------------------------------------------------
--  Secret values
--  A secret reports type() "number"/"string"/"boolean" but throws on any
--  comparison, arithmetic, concatenation or truth test. Every value that comes
--  from a unit or the client goes through these before it is branched on or
--  printed. issecretvalue is looked up once; on a client without it nothing
--  is secret.
-------------------------------------------------------------------------------
local issecret = issecretvalue

function ns.IsSecret(v)
    if issecret then return issecret(v) end
    return false
end

-- The value when it is safe to use, otherwise the fallback.
function ns.Plain(v, fallback)
    if issecret and issecret(v) then return fallback end
    return v
end

-- A printable string for any value, never touching a secret.
function ns.Text(v)
    if issecret and issecret(v) then return "<secret>" end
    return tostring(v)
end

function ns.Print(...)
    local n = select("#", ...)
    local parts = {}
    for i = 1, n do
        parts[i] = ns.Text((select(i, ...)))
    end
    local frame = DEFAULT_CHAT_FRAME
    local msg = ns.TAG .. ": " .. table.concat(parts, " ")
    if frame and frame.AddMessage then
        frame:AddMessage(msg)
    else
        print(msg)
    end
end

-------------------------------------------------------------------------------
--  Client identity
--  Forever is its own game type in the Mainline family. Compare the project ID
--  with WOW_PROJECT_CAMELOT while that constant exists; the constant was
--  expected to be renamed, so when it is gone fall back to the interface range
--  Forever reports (16xxx). Features still check the API they need.
-------------------------------------------------------------------------------
function ns.BuildInfo()
    local version, build, _, interface = GetBuildInfo()
    return version, build, interface
end

function ns.IsForever()
    local camelot = _G.WOW_PROJECT_CAMELOT
    local project = _G.WOW_PROJECT_ID
    if camelot ~= nil and project ~= nil then return project == camelot end
    local _, _, interface = ns.BuildInfo()
    return type(interface) == "number" and interface >= 16000 and interface < 20000
end

-------------------------------------------------------------------------------
--  Saved variables
--  Defaults only. AritlokUIDB itself is read and created inside ADDON_LOADED.
-------------------------------------------------------------------------------
ns.defaults = {
    schema = 4,
    theme = "gradient", -- "gradient" | "dark"
    shade = {
        enabled = true,
        strength = 55, -- 0-90: how deep the left end of a bar gets
        glow = 12, -- 0-60: how bright the right end gets
    },
    -- The menu bar's backdrop and long XP bar (the bar itself is EllesmereUI's).
    bar = {
        enabled = true,
        position = "BOTTOM", -- "BOTTOM" | "TOP"
        opacity = 80, -- backdrop, 0-100
        classWash = true, -- class-color wash at both ends
        showXP = true,
        xpLength = 320, -- length of the long XP bar
        xpOffset = 320, -- how far from the left screen edge it starts
        xpLong = false, -- set by the installer once EllesmereUI's own XP block is replaced
        clock24 = true,
    },
    -- What the installer applies; one key per entry in ns.Installer.options.
    install = {
        unitFrames = true,
        actionBars = true,
        dataBar = true,
        chat = true,
        rightSide = true,
        style = true,
        font = true,
        accent = true,
        scale = true,
        -- Other addons the installer can theme; one key per entry in
        -- ns.Installer.addons. Only offered when that addon is loaded.
        addons = {
            questie = true,
            questieTracker = true,
        },
        -- Hidden while out of combat; one key per entry in
        -- ns.Installer.combatOptions.
        combat = {
            actionBars = false,
            petBar = true,
            unitFrames = false,
            meters = true,
        },
    },
    -- Which EllesmereUI profile the installer writes to.
    profile = {
        mode = "shared", -- "shared": the profile named "AritlokUI". "own": the name below.
        name = "",
    },
    createdProfiles = {}, -- EllesmereUI profiles this addon made, by name
    questieOwnsTracker = false, -- the installer switched EllesmereUI's quest tracker off for Questie's
    installed = false,
    wizardSeen = false, -- the installer has been shown once on this account
}

local function MergeDefaults(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            MergeDefaults(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end
ns.MergeDefaults = MergeDefaults

-------------------------------------------------------------------------------
--  Events: one frame, one handler table keyed by event name. Each entry is the
--  list of callbacks for that event; modules add to it with ns.On.
-------------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
local handlers = {}
ns.handlers = handlers
ns.missingEvents = {}

-- Registers fn for event. Returns false when this client has no such event
-- (RegisterEvent raises on an unknown name; that is a plain Lua error, so a
-- pcall is the right tool here).
function ns.On(event, fn)
    local list = handlers[event]
    if not list then
        local ok = pcall(eventFrame.RegisterEvent, eventFrame, event)
        if not ok then
            ns.missingEvents[event] = true
            return false
        end
        list = {}
        handlers[event] = list
    end
    list[#list + 1] = fn
    return true
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    local list = handlers[event]
    if not list then return end
    for i = 1, #list do
        list[i](...)
    end
end)

-------------------------------------------------------------------------------
--  Combat queue
--  Anything that may touch a protected frame, or that EllesmereUI itself
--  refuses in combat, goes through here and runs on PLAYER_REGEN_ENABLED.
-------------------------------------------------------------------------------
local combatQueue = {}

function ns.RunOutOfCombat(fn)
    if InCombatLockdown() then
        combatQueue[#combatQueue + 1] = fn
        return false
    end
    fn()
    return true
end

ns.On("PLAYER_REGEN_ENABLED", function()
    if #combatQueue == 0 then return end
    local run = combatQueue
    combatQueue = {}
    for i = 1, #run do
        run[i]()
    end
end)

-------------------------------------------------------------------------------
--  Lifecycle
-------------------------------------------------------------------------------
ns.On("ADDON_LOADED", function(loaded)
    if loaded ~= addonName then return end
    if type(AritlokUIDB) ~= "table" then AritlokUIDB = {} end
    -- Saved settings from earlier versions.
    local saved = AritlokUIDB
    if saved.schema == 1 then
        -- Schema 2 lowered the default right-end glow (30 washed pale class
        -- colors out to near white). A saved 30 is the old default.
        if type(saved.shade) == "table" and saved.shade.glow == 30 then saved.shade.glow = 12 end
        saved.schema = 2
    end
    if saved.schema == 2 then
        -- Schema 3 dropped the built-in bar and the undo: clear what they kept.
        saved.previousProfile, saved.previousScale = nil, nil
        if type(saved.bar) == "table" then
            local bar = saved.bar
            -- The long XP bar only shows once the installer has made room for it.
            bar.xpLong = (bar.mode == "eui" and bar.xpLong) and true or false
            bar.mode, bar.micro, bar.height, bar.localTime = nil, nil, nil, nil
        end
        if type(saved.install) == "table" then
            saved.install.accentClass, saved.install.minimap = nil, nil
        end
        saved.schema = 3
    end
    if saved.schema == 3 then
        -- Schema 4 added the profile choice and addon integrations; the new
        -- keys come from the defaults merge below.
        saved.schema = 4
    end
    ns.db = MergeDefaults(AritlokUIDB, ns.defaults)
    eventFrame:UnregisterEvent("ADDON_LOADED")
    handlers["ADDON_LOADED"] = nil
end)

ns.On("PLAYER_LOGIN", function()
    local _, _, interface = ns.BuildInfo()
    if interface ~= ns.EXPECTED_INTERFACE then
        ns.Print(
            string.format(
                ns.L["written for interface %s, this client reports %s. Run /aui probe and retest."],
                tostring(ns.EXPECTED_INTERFACE),
                ns.Text(interface)
            )
        )
    end
end)

-------------------------------------------------------------------------------
--  Capability probe: what this build actually has. Nothing here is assumed.
-------------------------------------------------------------------------------
local function Has(path)
    local node = _G
    for part in string.gmatch(path, "[^%.]+") do
        if type(node) ~= "table" then return false end
        node = node[part]
    end
    return node ~= nil
end
ns.Has = Has

function ns.Probe()
    local version, build, interface = ns.BuildInfo()
    ns.Print("client " .. ns.Text(version) .. " build " .. ns.Text(build) .. " interface " .. ns.Text(interface))
    ns.Print(
        "WOW_PROJECT_ID="
            .. ns.Text(_G.WOW_PROJECT_ID)
            .. " CAMELOT="
            .. ns.Text(_G.WOW_PROJECT_CAMELOT)
            .. " MAINLINE="
            .. ns.Text(_G.WOW_PROJECT_MAINLINE)
            .. " CLASSIC="
            .. ns.Text(_G.WOW_PROJECT_CLASSIC)
            .. " -> Forever: "
            .. ns.Text(ns.IsForever())
    )

    local checks = {
        "issecretvalue",
        "CreateColor",
        "C_Timer.After",
        "UnitXP",
        "UnitXPMax",
        "UnitLevel",
        "FCF_DockFrame",
        "Enum.DamageMeterType",
        "RAID_CLASS_COLORS",
        "LibStub",
        "EllesmereUI",
        "EllesmereUIDB",
        "EllesmereUI.RegisterPlugin",
        "EllesmereUI.OpenPlugin",
        "EllesmereUI.SaveCurrentAsProfile",
        "EllesmereUI.SwitchProfile",
        "EllesmereUI.GetActiveProfileName",
        "EllesmereUI.GetActiveProfileData",
        "EllesmereUI.SetActiveProfileAccent",
        "EllesmereUI.RefreshAccent",
        "EllesmereUI.GetAccentColor",
        "EllesmereUI.RegAccent",
        "EllesmereUI.ApplyFirstInstallLook",
        "EllesmereUI.GetFontPath",
        "EllesmereUI.GetFontsDB",
        "EllesmereUI.PP.SetUIScale",
        "EllesmereUI._ModuleNS.EllesmereUIDataBars",
        "EllesmereUIUnitFrames_Player",
        "EllesmereUIUnitFrames_Target",
    }
    local present, absent = {}, {}
    for i = 1, #checks do
        local name = checks[i]
        if Has(name) then
            present[#present + 1] = name
        else
            absent[#absent + 1] = name
        end
    end
    ns.Print("present: " .. table.concat(present, ", "))
    ns.Print("absent: " .. (#absent > 0 and table.concat(absent, ", ") or "none"))

    local missing = {}
    for event in pairs(ns.missingEvents) do
        missing[#missing + 1] = event
    end
    ns.Print("events this client rejected: " .. (#missing > 0 and table.concat(missing, ", ") or "none"))

    local eui = _G.EllesmereUI
    if type(eui) == "table" then
        if ns.Installer then ns.Print("tested with EllesmereUI " .. ns.Installer.TESTED_EUI) end
        ns.Print(
            "EllesmereUI "
                .. ns.Text(eui.VERSION)
                .. ", plugin API "
                .. ns.Text(eui.PLUGIN_API_VERSION)
                .. ", IS_FOREVER="
                .. ns.Text(eui.IS_FOREVER)
        )
    end
end
