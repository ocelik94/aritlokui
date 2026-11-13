local addonName, ns = ...

-------------------------------------------------------------------------------
--  Installer step: party / raid frames and nameplates, in the same look as
--  the unit frames: the flat bar texture, the blue-black bar background, a
--  1-pixel black border. Only the look; their size and position stay as they
--  are. Text follows EllesmereUI's global font in both modules, which the font
--  step already sets. Part of the "Unit frames" option.
--
--  The Dark theme carries over to the party and raid frames (their own dark
--  health color mode). Nameplates have no dark mode, so they keep their
--  reaction colors in both themes.
--
--  RETEST after an EllesmereUI update (read from 9.8.4): both modules keep
--  their settings flat in their own table under the profile's addons.
--    EllesmereUIRaidFrames (EllesmereUIRaidFrames.lua, defaults ~l.430-524):
--      healthBarTexture, healthBarOpacity, healthColorMode ("class" | "dark"
--      | ...), customBgColor, bgClassColored, bgDarkness (background alpha,
--      0-100), borderSize, borderColor, borderAlpha. Party frames read the
--      same keys while their health bar section is synced with raid (the
--      default).
--    EllesmereUINameplates (EllesmereUINameplates.lua, defaults ~l.485-630):
--      healthBarTexture, bgColor, bgAlpha (0-1), showBorder, borderSize,
--      borderColor.
--  Textures are stored as "sm:<LibSharedMedia name>", which both resolve
--  through EllesmereUI.ResolveTexturePath.
-------------------------------------------------------------------------------

local I = ns.Installer

local function BarBackground() return { r = ns.PANEL.r, g = ns.PANEL.g, b = ns.PANEL.b } end

local function WriteRaidFrames(ctx)
    local rf = ctx.addons.EllesmereUIRaidFrames
    if type(rf) ~= "table" then return false end
    rf.healthBarTexture = ns.FLAT_KEY
    rf.healthBarOpacity = 100
    rf.healthColorMode = (ctx.theme == "dark") and "dark" or "class"
    rf.customBgColor = BarBackground()
    rf.bgClassColored = false
    rf.bgDarkness = 90
    rf.borderSize = 1
    rf.borderColor = { r = 0, g = 0, b = 0 }
    rf.borderAlpha = 1
    return true
end

local function WriteNameplates(ctx)
    local np = ctx.addons.EllesmereUINameplates
    if type(np) ~= "table" then return false end
    np.healthBarTexture = ns.FLAT_KEY
    np.bgColor = BarBackground()
    np.bgAlpha = 0.9
    np.showBorder = true
    np.borderSize = 1
    np.borderColor = { r = 0, g = 0, b = 0 }
    return true
end

-- Right after the unit frames (100).
I.AddStep({
    order = 105,
    option = "unitFrames",
    run = function(ctx)
        if WriteRaidFrames(ctx) then
            ctx:Done("party and raid frames")
        else
            ctx:Skip("party and raid frames (EllesmereUI Raid Frames is not loaded)")
        end
        if WriteNameplates(ctx) then
            ctx:Done("nameplates")
        else
            ctx:Skip("nameplates (EllesmereUI Nameplates is not loaded)")
        end
    end,
})

-------------------------------------------------------------------------------
--  Healer layout (option "healer"): party and raid frames move to the center
--  of the screen, in the band between the cooldown manager rows (which end 366
--  up) and the stance bar over the action bars, so the frames you heal sit
--  where you are already looking. They get smaller to fit: 88 x 36, party in
--  one row of five, raid in groups of five going down, groups side by side.
--  A 40-player raid grows to the right from there, still below the unit
--  frames.
--
--  The values it replaces are kept (AritlokUIDB.healerBefore) and put back
--  when the option is switched off and the installer runs again.
--
--  RETEST after an EllesmereUI update (read from 9.8.4):
--    raid: unlockPos {point, relPoint, x, y} on UIParent, the TOP LEFT of the
--      20-player footprint (EUI_RaidFrames_Reload.lua _RFBaseTopLeft);
--      frameWidth, frameHeight, unitGrowth, groupGrowth.
--    party: partyUnlockPos (same shape, the party container's own point),
--      partyFrameWidth, partyFrameHeight, partyHorizontal.
--    EllesmereUIDB._capturedOnce_RF: until it is set, EllesmereUI replaces
--      unlockPos with its first-install default at login
--      (EUI_RaidFrames_Lifecycle.lua OnEnable).
--    An element anchor set in unlock mode (EllesmereUIDB.unlockAnchors)
--    takes priority over these positions.
-------------------------------------------------------------------------------
local KEPT = { "unlockPos", "partyUnlockPos", "frameWidth", "frameHeight", "unitGrowth", "groupGrowth" }
local KEPT_PARTY = { "partyFrameWidth", "partyFrameHeight", "partyHorizontal" }

local function Copy(v)
    if type(v) ~= "table" then return v end
    local out = {}
    for k, x in pairs(v) do
        out[k] = x
    end
    return out
end

local function Keep(db, rf)
    if db.healerBefore then return end -- already kept by an earlier install
    local before = {}
    for _, list in ipairs({ KEPT, KEPT_PARTY }) do
        for i = 1, #list do
            before[list[i]] = Copy(rf[list[i]])
        end
    end
    db.healerBefore = before
end

local function Restore(db, rf)
    local before = db.healerBefore
    if type(before) ~= "table" then return false end
    for _, list in ipairs({ KEPT, KEPT_PARTY }) do
        for i = 1, #list do
            local key = list[i]
            rf[key] = Copy(before[key]) -- nil when it was unset before
        end
    end
    db.healerBefore = nil
    return true
end

I.AddStep({
    order = 106,
    option = nil, -- runs either way: placing, or putting back
    run = function(ctx)
        local rf = ctx.addons.EllesmereUIRaidFrames
        if type(rf) ~= "table" then
            if ctx.want.healer then ctx:Skip("healer layout (EllesmereUI Raid Frames is not loaded)") end
            return
        end
        if not ctx.want.healer then
            if Restore(ctx.db, rf) then ctx:Done("party and raid frames back where they were") end
            return
        end
        local g = ctx:Geometry()
        if not g then
            ctx:Skip("healer layout")
            return
        end

        Keep(ctx.db, rf)
        local S = g.S
        local w, h = S(88), S(36)
        local top = g.Y(366) - S(10) -- just under the cooldown manager rows

        rf.frameWidth, rf.frameHeight = w, h
        rf.unitGrowth, rf.groupGrowth = "DOWN", "RIGHT"
        -- The point is the top of the 20-player footprint (four groups side
        -- by side), so the usual raid size sits centered.
        rf.unlockPos = { point = "TOP", relPoint = "CENTER", x = 0, y = top }

        rf.partyFrameWidth, rf.partyFrameHeight = w, h
        rf.partyHorizontal = true
        rf.partyUnlockPos = { point = "TOP", relPoint = "CENTER", x = 0, y = top }

        -- Without this, EllesmereUI's first-install pass would move the raid
        -- frames back to its default spot at the next login.
        if type(_G.EllesmereUIDB) == "table" then _G.EllesmereUIDB._capturedOnce_RF = true end
        ctx:Done("healer layout")
    end,
})
