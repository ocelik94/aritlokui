local addonName, ns = ...

-------------------------------------------------------------------------------
--  BugSack window in the AritlokUI look: the flat dark panel with a thin
--  black border and an accent line along the top, in place of the Blizzard
--  frame art, and the error text in the interface font (a monospace font
--  keeps stack traces lined up). Switched on by the installer
--  (Modules/Installer/Addons.lua sets AritlokUIDB.bugSackSkin) and only read
--  at login, so it takes effect with the install's reload.
--
--  BugSack builds its window the first time it opens. Its own functions are
--  followed with hooksecurefunc (a post-hook: BugSack runs unchanged); the
--  window is a plain addon frame, never protected.
--
--  RETEST after a BugSack update (read from v12.1.9, sack.lua): the addon
--  table is the global `BugSack` (only set when BugGrabber is loaded), the
--  window is "BugSackFrame" (PortraitFrameTemplate on Forever), the text
--  "BugSackScrollText", the font size choice BugSackDB.fontSize (one of four
--  GameFontHighlight* names); OpenSack and OpenConfig show the window.
-------------------------------------------------------------------------------

-- BugSack's font size choices, as point sizes.
local SIZES = {
    GameFontHighlightSmall = 11,
    GameFontHighlight = 12,
    GameFontHighlightMedium = 13,
    GameFontHighlightLarge = 15,
}

-- Blizzard frame art of the template (and window.Bg, below), hidden behind
-- the flat panel.
local ART = { "NineSlice", "TopTileStreaks", "PortraitContainer", "portrait" }

local skinned = false

local function Edge(window, a, b, horizontal)
    local t = window:CreateTexture(nil, "BORDER")
    t:SetColorTexture(0, 0, 0, 1)
    t:SetPoint(a)
    t:SetPoint(b)
    if horizontal then
        t:SetHeight(1)
    else
        t:SetWidth(1)
    end
end

local function SkinWindow(window)
    for i = 1, #ART do
        local part = window[ART[i]]
        if type(part) == "table" and part.SetAlpha then part:SetAlpha(0) end
    end
    if type(window.Bg) == "table" and window.Bg.SetAlpha then window.Bg:SetAlpha(0) end
    local bg = window:CreateTexture(nil, "BACKGROUND", nil, -8)
    bg:SetAllPoints()
    bg:SetColorTexture(ns.PANEL.r, ns.PANEL.g, ns.PANEL.b, 0.97)
    Edge(window, "TOPLEFT", "TOPRIGHT", true)
    Edge(window, "BOTTOMLEFT", "BOTTOMRIGHT", true)
    Edge(window, "TOPLEFT", "BOTTOMLEFT", false)
    Edge(window, "TOPRIGHT", "BOTTOMRIGHT", false)
    window.aritlokLine = window:CreateTexture(nil, "ARTWORK")
    window.aritlokLine:SetPoint("TOPLEFT", 1, -1)
    window.aritlokLine:SetPoint("TOPRIGHT", -1, -1)
    window.aritlokLine:SetHeight(2)
end

-- After every open: the accent may have changed, and BugSack's font size
-- option sets its own font object on the text.
local function Apply()
    local window = _G.BugSackFrame
    if type(window) ~= "table" or not window.CreateTexture then return end
    if not skinned then
        SkinWindow(window)
        skinned = true
    end
    local r, g, b = ns.GetAccent()
    window.aritlokLine:SetColorTexture(r, g, b, 1)
    local text = _G.BugSackScrollText
    if type(text) == "table" and text.SetFont then
        local db = _G.BugSackDB
        local size = SIZES[type(db) == "table" and db.fontSize or ""] or 12
        ns.SetFont(text, size)
    end
end

ns.On("PLAYER_LOGIN", function()
    local db = ns.db
    local sack = _G.BugSack
    if type(db) ~= "table" or not db.bugSackSkin or type(sack) ~= "table" then return end
    if type(sack.OpenSack) == "function" then hooksecurefunc(sack, "OpenSack", Apply) end
    if type(sack.OpenConfig) == "function" then hooksecurefunc(sack, "OpenConfig", Apply) end
end)
