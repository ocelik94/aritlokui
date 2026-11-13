local addonName, ns = ...

-------------------------------------------------------------------------------
--  Bar gradients
--  The gradient look: every EllesmereUI unit frame bar (health, power, cast)
--  and the health bar of every party and raid frame runs from a deepened
--  left end to a brightened right end of whatever color EllesmereUI gave it.
--
--  It is done with two extra textures per bar, both pinned to the bar's own
--  fill texture: a "shade" painted black -> clear from the left, and a "glow"
--  painted clear -> white from the right with additive blending. The client
--  sizes the fill, the overlays follow it. Nothing here reads health, power,
--  names or the bar's color, so there is no arithmetic on them and it works
--  the same when they are secret.
--
--  The frames are EllesmereUI's own (addon-created) frames, looked up by their
--  global names. Blizzard's unit frames are never touched, no attribute is
--  written, and no EllesmereUI function is hooked: the overlays are re-pinned
--  on the events below instead, because EllesmereUI replaces a fill texture
--  when a bar texture setting changes.
-------------------------------------------------------------------------------

local FRAME_NAMES = {
    "EllesmereUIUnitFrames_Player",
    "EllesmereUIUnitFrames_Target",
    "EllesmereUIUnitFrames_TargetTarget",
    "EllesmereUIUnitFrames_Focus",
    "EllesmereUIUnitFrames_FocusTarget",
    "EllesmereUIUnitFrames_Pet",
    "EllesmereUIUnitFrames_Boss1",
    "EllesmereUIUnitFrames_Boss2",
    "EllesmereUIUnitFrames_Boss3",
    "EllesmereUIUnitFrames_Boss4",
    "EllesmereUIUnitFrames_Boss5",
}

local PET_FRAME = "EllesmereUIUnitFrames_Pet"

-------------------------------------------------------------------------------
--  Party and raid frames (EllesmereUIRaidFrames). Their buttons are listed by
--  the module itself; a button's health bar is not a field on the button but
--  in the module's per-frame data table, read through its GetFFD(button).
--  Both are internal: everything is checked and a miss just leaves those
--  frames without gradients. The buttons are secure, so the overlays are only
--  added outside combat; overlays already there keep following the fill.
--
--  RETEST after an EllesmereUI update (read from 9.8.4):
--  EllesmereUI._ModuleNS.EllesmereUIRaidFrames with _partyAllButtons
--  (EUI_RaidFrames_Party.lua), _internals.allButtons
--  (EllesmereUIRaidFrames.lua) and GetFFD(button).health, a StatusBar
--  (EUI_RaidFrames_Style.lua).
-------------------------------------------------------------------------------
local groupQueued = false

local function RaidModule()
    local eui = _G.EllesmereUI
    local registry = type(eui) == "table" and eui._ModuleNS
    local mod = type(registry) == "table" and registry.EllesmereUIRaidFrames
    if type(mod) == "table" and type(mod.GetFFD) == "function" then return mod end
    return nil
end

local function ForEachGroupHealthBar(fn)
    local mod = RaidModule()
    if not mod then return end
    local lists = { mod._partyAllButtons }
    -- _internals refuses unknown keys with an error; that is an ordinary Lua
    -- error, so pcall is the right tool for reading it.
    local ok, raid = pcall(function() return mod._internals.allButtons end)
    if ok then lists[#lists + 1] = raid end
    for i = 1, #lists do
        local list = lists[i]
        if type(list) == "table" then
            for j = 1, #list do
                local button = list[j]
                local got, data = pcall(mod.GetFFD, button)
                local bar = got and type(data) == "table" and data.health
                if type(bar) == "table" then fn(bar) end
            end
        end
    end
end

-- Fields on an EllesmereUI unit frame that hold a StatusBar.
local BAR_FIELDS = { "Health", "Power", "Castbar" }

-- Overlay textures keyed by status bar. Kept here, never as a field on an
-- EllesmereUI frame.
local overlays = {}

local shadeFrom, shadeTo, glowFrom, glowTo
local supported

local function Supported()
    if supported == nil then
        supported = (type(CreateColor) == "function")
        if supported then
            shadeFrom = CreateColor(0, 0, 0, 0.55)
            shadeTo = CreateColor(0, 0, 0, 0)
            glowFrom = CreateColor(1, 1, 1, 0)
            glowTo = CreateColor(1, 1, 1, 0.3)
        end
    end
    return supported
end

local function OverlaysFor(bar)
    local o = overlays[bar]
    if not o then
        o = {}
        overlays[bar] = o
    end
    if not o.shade then
        o.shade = bar:CreateTexture(nil, "ARTWORK", nil, 6)
        o.shade:SetColorTexture(1, 1, 1, 1)
        o.glow = bar:CreateTexture(nil, "ARTWORK", nil, 7)
        o.glow:SetColorTexture(1, 1, 1, 1)
        o.glow:SetBlendMode("ADD")
    end
    return o
end

-- A flat darkening over one bar, used to set the pet's health bar apart from
-- the player's: both are the player's class color, the pet's a shade darker.
-- It is a plain black texture pinned to the fill, so it needs no knowledge of
-- the color underneath and works for every class.
local function ApplyDim(bar, alpha)
    if type(bar) ~= "table" or not bar.GetStatusBarTexture or not bar.CreateTexture then return end
    local o = overlays[bar]
    if alpha <= 0 then
        if o and o.dim then o.dim:Hide() end
        return
    end
    local fill = bar:GetStatusBarTexture()
    if not fill then return end
    if not o then
        o = {}
        overlays[bar] = o
    end
    if not o.dim then o.dim = bar:CreateTexture(nil, "ARTWORK", nil, 5) end
    o.dim:ClearAllPoints()
    o.dim:SetAllPoints(fill)
    o.dim:SetColorTexture(0, 0, 0, alpha)
    o.dim:Show()
end

local function ApplyBar(bar, show, shadeAlpha, glowAlpha)
    if type(bar) ~= "table" or not bar.GetStatusBarTexture or not bar.CreateTexture then return end

    if not show then
        local existing = overlays[bar]
        if existing and existing.shade then
            existing.shade:Hide()
            existing.glow:Hide()
        end
        return
    end

    local fill = bar:GetStatusBarTexture()
    if not fill then return end

    local o = OverlaysFor(bar)

    o.shade:ClearAllPoints()
    o.shade:SetAllPoints(fill)
    shadeFrom:SetRGBA(0, 0, 0, shadeAlpha)
    o.shade:SetGradient("HORIZONTAL", shadeFrom, shadeTo)
    o.shade:SetShown(shadeAlpha > 0)

    o.glow:ClearAllPoints()
    o.glow:SetAllPoints(fill)
    glowTo:SetRGBA(1, 1, 1, glowAlpha)
    o.glow:SetGradient("HORIZONTAL", glowFrom, glowTo)
    o.glow:SetShown(glowAlpha > 0)
end

local function Clamp(v, fallback, low, high)
    if type(v) ~= "number" then v = fallback end
    if v < low then
        return low
    elseif v > high then
        return high
    end
    return v
end

function ns.RefreshShades()
    local db = ns.db
    if not db or not Supported() then return end

    -- EllesmereUI's dark theme paints every bar one flat dark color; a
    -- gradient on top of that only muddies it.
    local show = db.shade.enabled and db.theme ~= "dark"
    local shadeAlpha = Clamp(db.shade.strength, 55, 0, 90) / 100
    local glowAlpha = Clamp(db.shade.glow, 12, 0, 60) / 100

    for i = 1, #FRAME_NAMES do
        local frame = _G[FRAME_NAMES[i]]
        if type(frame) == "table" then
            for j = 1, #BAR_FIELDS do
                ApplyBar(frame[BAR_FIELDS[j]], show, shadeAlpha, glowAlpha)
            end
        end
    end

    -- Party and raid frames: health bars only. In combat this waits for the
    -- end of the fight; refreshes meanwhile (target changes) queue it once.
    if InCombatLockdown() then
        if not groupQueued then
            groupQueued = true
            ns.RunOutOfCombat(function()
                groupQueued = false
                ns.RefreshShades()
            end)
        end
    else
        ForEachGroupHealthBar(function(bar) ApplyBar(bar, show, shadeAlpha, glowAlpha) end)
    end

    -- The pet's health bar, darkened. Not in the dark theme, where bars are
    -- not class-colored in the first place.
    local pet = _G[PET_FRAME]
    if type(pet) == "table" then
        local dim = (db.theme ~= "dark") and Clamp(db.shade.petDim, 30, 0, 70) / 100 or 0
        ApplyDim(pet.Health, dim)
    end
end

local function Refresh() ns.RefreshShades() end

-- EllesmereUI builds its frames at login and finishes its own setup a frame
-- later, so the first pass is repeated shortly after entering the world.
ns.On("PLAYER_ENTERING_WORLD", function()
    Refresh()
    if C_Timer and C_Timer.After then
        C_Timer.After(1, Refresh)
        C_Timer.After(4, Refresh)
    end
end)

ns.On("PLAYER_TARGET_CHANGED", Refresh)
ns.On("PLAYER_FOCUS_CHANGED", Refresh) -- rejected harmlessly if this client has no focus
ns.On("UNIT_PET", Refresh)
ns.On("INSTANCE_ENCOUNTER_ENGAGE_UNIT", Refresh) -- boss frames
ns.On("PLAYER_REGEN_ENABLED", Refresh) -- EllesmereUI re-applies settings after combat
-- Party and raid buttons get their unit (and on first use their health bar)
-- when the group changes; EllesmereUI styles them a moment later.
ns.On("GROUP_ROSTER_UPDATE", function()
    Refresh()
    if C_Timer and C_Timer.After then C_Timer.After(1, Refresh) end
end)
