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
