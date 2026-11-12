local addonName, ns = ...

-------------------------------------------------------------------------------
--  RestedXP Guides theme.
--  RestedXP has its own theme system: a theme is a table of colors, a font and
--  a texture folder, and the guide window, arrow, map pins and tooltips are
--  all painted from the active one. This file hands it one more theme, built
--  from EllesmereUI's accent color and font. Nothing of RestedXP's is hooked,
--  replaced or repainted from here; choosing the theme is the installer's job
--  (Modules/Installer/Addons.lua) or the player's, in RestedXP's own options.
--
--  RETEST after a RestedXP update (read from v4.11.36, Themes.lua):
--    * themes are taken from the global list `RXPGuides_Themes` during its
--      OnInitialize, and from `addon:RegisterTheme(theme)` afterwards
--    * the fields below (background, bottomFrameBG, bottomFrameHighlight,
--      mapPins, tooltip, font, textColor, texturePath, edges, bgTextures)
--    * `addon:ReloadTheme()` repaints after a change
-------------------------------------------------------------------------------

local RXP_ADDON = "RXPGuides"
local THEME = "AritlokUI"
ns.RXP_THEME = THEME

-- RestedXP's own dark texture set: neutral grey icons, checkboxes, scroll bar
-- and borders, so the accent color is the only color in the window.
local TEXTURES = "Interface/AddOns/" .. RXP_ADDON .. "/Textures/DarkMode/"

-- One table for the life of the session. RestedXP keeps a reference to it, so
-- a color change is written into this table rather than into a new one.
local theme = {
    name = THEME,
    displayName = "AritlokUI",
    author = "AritlokUI",
    applicable = true,
    texturePath = TEXTURES,
    headerTexture = "rxp-banner",
    textColor = { 1, 1, 1 },
    background = { 0.05, 0.05, 0.06, 0.92 },
    bottomFrameBG = { 0.09, 0.09, 0.1, 0.92 },
    bgTextures = { edge = ns.media.white, bottom = ns.media.white },
    edges = { edge = TEXTURES .. "rxp-borders", guideName = TEXTURES .. "rxp-borders" },
}

-- Fills in everything that follows the accent color and the font. Returns
-- true when something changed, so a repaint is only asked for when needed.
local function Fill()
    local r, g, b = ns.GetAccent()
    local tooltip = "|cff" .. ns.Hex(r, g, b)
    local font = (ns.GetFont())
    if theme.tooltip == tooltip and theme.font == font then return false end
    theme.bottomFrameHighlight = { r, g, b, 0.5 } -- the step under the mouse
    theme.mapPins = { r, g, b, 1 }
    theme.tooltip = tooltip
    theme.font = font
    return true
end
Fill()

-- RestedXP's addon object (an AceAddon), or nil when it is not loaded.
function ns.GetRXP()
    local ace = LibStub and LibStub("AceAddon-3.0", true)
    if not ace then return nil end
    local rxp = ace:GetAddon(RXP_ADDON, true)
    if type(rxp) == "table" then return rxp end
    return nil
end

-- This addon loads before RestedXP (alphabetical order), so the theme waits
-- in the list RestedXP reads when it starts up.
if type(_G.RXPGuides_Themes) ~= "table" then _G.RXPGuides_Themes = {} end
table.insert(_G.RXPGuides_Themes, theme)

-- True when RestedXP is showing this theme.
local function IsActive(rxp)
    local settings = rxp.settings
    local profile = type(settings) == "table" and settings.profile
    return type(profile) == "table" and profile.activeTheme == THEME
end

-- Repaints RestedXP's frames. Its guide window holds item buttons, which are
-- protected, so this waits for the end of combat.
local function Repaint(rxp)
    if not (IsActive(rxp) and rxp.ReloadTheme) then return end
    ns.RunOutOfCombat(function() rxp:ReloadTheme() end)
end

-- Should RestedXP have started before this file ran (another load order), the
-- list above was already read and emptied: register directly instead.
local function EnsureRegistered()
    local rxp = ns.GetRXP()
    if not rxp then return nil end
    local known = type(rxp.themes) == "table" and rxp.themes[THEME]
    if known ~= theme and rxp.RegisterTheme then
        rxp:RegisterTheme(theme)
        Repaint(rxp)
    end
    return rxp
end

ns.On("PLAYER_LOGIN", function()
    -- EllesmereUI's accent is final by now; while the addons were loading
    -- it may still have been its default.
    local changed = Fill()
    local rxp = EnsureRegistered()
    if not rxp then return end
    if changed then Repaint(rxp) end

    local eui = _G.EllesmereUI
    if type(eui) == "table" and eui.RegAccent then
        eui.RegAccent({
            type = "callback",
            fn = function()
                if Fill() then Repaint(rxp) end
            end,
        })
    end
end)
