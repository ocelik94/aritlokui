local addonName, ns = ...

-------------------------------------------------------------------------------
--  Installer step: other addons.
--  Settings for addons that are not part of EllesmereUI, so they match the
--  rest of the interface. Each entry is only offered when its addon is loaded,
--  and only writes that addon's own saved settings; everything takes effect
--  with the reload at the end of the install.
--
--  Covered so far: Questie and RestedXP Guides.
--
--  RETEST after a Questie update: the setting names below were read from
--  Questie's source as installed, and it is reached through the global it
--  publishes (`Questie`).
--
--  RETEST after a RestedXP update: `activeTheme` in its settings profile
--  (SettingsPanel.lua, v4.11.36). The theme itself is Modules/RestedXP.lua.
-------------------------------------------------------------------------------

local I = ns.Installer
local Sub = I.Sub

-- Questie's saved profile, or nil when Questie is not loaded.
local function QuestieProfile()
    local questie = _G.Questie
    local db = type(questie) == "table" and questie.db
    local profile = type(db) == "table" and db.profile
    if type(profile) == "table" then return profile end
    return nil
end

-------------------------------------------------------------------------------
--  The list: one entry, and so one switch, per addon. `key` is the field in
--  AritlokUIDB.install.addons. Titles are addon names; descriptions are
--  English here and translated where they are shown.
-------------------------------------------------------------------------------
I.addons = {
    {
        key = "questie",
        title = "Questie",
        desc = "Its quest tracker replaces EllesmereUI's.",
        detect = function() return QuestieProfile() ~= nil end,
        apply = function(ctx)
            local q = QuestieProfile()
            -- Questie looks fonts up by their LibSharedMedia name.
            q.trackerFontHeader = ns.FONT_NAME
            q.trackerFontZone = ns.FONT_NAME
            q.trackerFontQuest = ns.FONT_NAME
            q.trackerFontObjective = ns.FONT_NAME
            q.trackerFontSizeHeader = 13
            q.trackerFontSizeZone = 12
            q.trackerFontSizeQuest = 11
            q.trackerFontSizeObjective = 11
            q.trackerFontOutline = ""
            q.trackerBackdropEnabled = false
            q.trackerBorderEnabled = false
            q.trackerEnabled = true

            -- EllesmereUI's quest tracker module off: `enabled` is the module
            -- switch, customTrackerPick = false is its own "do not use our
            -- tracker" choice. Questie then owns the quest list by itself.
            local eqt = ctx.addons.EllesmereUIQuestTracker
            if type(eqt) == "table" then
                local t = Sub(eqt, "questTracker")
                t.enabled = false
                t.customTrackerPick = false
                ctx.db.questieOwnsTracker = true -- remembered, so it can be handed back
            end

            -- Same spot the installer gives EllesmereUI's tracker. Questie
            -- stores { point, frame name, relative point, x, y }.
            local g = ctx:Geometry()
            if g then
                q.trackerSetpoint = "TOPRIGHT"
                q.TrackerLocation = { "TOPRIGHT", "UIParent", "TOPRIGHT", -g.S(4), -g.S(346) }
                q.trackerLocked = true
            end
            ctx:Done("Questie quest tracker in place of EllesmereUI's")
        end,
        -- Option switched off after an earlier install had it on: give the
        -- quest list back to EllesmereUI's tracker.
        revert = function(ctx)
            if not ctx.db.questieOwnsTracker then return end
            local eqt = ctx.addons.EllesmereUIQuestTracker
            if type(eqt) == "table" then
                local t = Sub(eqt, "questTracker")
                t.enabled = true
                t.customTrackerPick = nil
            end
            ctx.db.questieOwnsTracker = false
        end,
    },
}

-- RestedXP's settings profile, or nil when RestedXP is not loaded (or has
-- not set its settings up yet).
local function RXPProfile()
    local rxp = ns.GetRXP()
    local settings = type(rxp) == "table" and rxp.settings
    local profile = type(settings) == "table" and settings.profile
    if type(profile) == "table" then return profile end
    return nil
end

I.addons[#I.addons + 1] = {
    key = "restedxp",
    title = "RestedXP",
    desc = "Guide window in the AritlokUI theme.",
    detect = function() return RXPProfile() ~= nil end,
    apply = function(ctx)
        local p = RXPProfile()
        if p.activeTheme ~= ns.RXP_THEME then
            ctx.db.rxpThemeBefore = p.activeTheme -- remembered, so it can be handed back
            p.activeTheme = ns.RXP_THEME
        end
        ctx:Done("RestedXP theme")
    end,
    -- Option switched off after an earlier install had it on: back to the
    -- theme RestedXP had before ("Default" is its own name for its standard).
    revert = function(ctx)
        local p = RXPProfile()
        if p.activeTheme ~= ns.RXP_THEME then return end
        local before = ctx.db.rxpThemeBefore
        p.activeTheme = type(before) == "string" and before or "Default"
        ctx.db.rxpThemeBefore = nil
    end,
}

-- The entries whose addon is loaded.
function I.DetectedAddons()
    local found = {}
    for i = 1, #I.addons do
        local entry = I.addons[i]
        if entry.detect() then found[#found + 1] = entry end
    end
    return found
end

-- After the right-edge step (130), which places EllesmereUI's own tracker.
I.AddStep({
    order = 140,
    option = nil,
    run = function(ctx)
        local want = ctx.want.addons
        if type(want) ~= "table" then return end
        local found = I.DetectedAddons()
        for i = 1, #found do
            local entry = found[i]
            if want[entry.key] then
                entry.apply(ctx)
            elseif entry.revert then
                entry.revert(ctx)
            end
        end
    end,
})
