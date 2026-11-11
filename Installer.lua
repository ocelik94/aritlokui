local addonName, ns = ...

-------------------------------------------------------------------------------
--  Theme installer
--  Puts the AritlokUI look onto EllesmereUI without touching the profile you
--  are using: it copies the active EllesmereUI profile to one named
--  "AritlokUI", switches to it, and changes settings there. /aui restore
--  switches back.
--
--  Only EllesmereUI's own profile functions and saved settings are used
--  (SaveCurrentAsProfile, SwitchProfile, GetActiveProfileData, SetAccentColor,
--  ApplyFirstInstallLook). Every setting key written below was read out of the
--  EllesmereUI 9.8.4 source; RETEST them after an EllesmereUI update.
--
--  Reload rule on Forever: addon code may reload only from inside a click or
--  key press, and only as the first thing that click does. So nothing here
--  reloads. The installer finishes its writes and then shows a prompt whose
--  button does nothing but reload.
-------------------------------------------------------------------------------

local PROFILE_NAME = "AritlokUI"
ns.PROFILE_NAME = PROFILE_NAME

local MAIN_BARS = { "MainBar", "Bar2", "Bar3", "Bar4", "Bar5", "Bar6", "Bar7", "Bar8" }

-------------------------------------------------------------------------------
--  Reload prompt (own frame; no StaticPopup, no Blizzard dialog code)
-------------------------------------------------------------------------------
local prompt

local function MakeButton(parent, label, r, g, b)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(130, 26)
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(r, g, b, 0.85)
    local hover = button:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints()
    hover:SetColorTexture(1, 1, 1, 0.12)
    local text = button:CreateFontString(nil, "OVERLAY")
    ns.SetFont(text, 12)
    text:SetPoint("CENTER")
    text:SetTextColor(1, 1, 1)
    text:SetText(label)
    button.label = text
    return button
end
ns.MakeButton = MakeButton

local function ShowReloadPrompt(message)
    if not prompt then
        prompt = CreateFrame("Frame", "AritlokUIReloadPrompt", UIParent)
        prompt:SetSize(420, 150)
        prompt:SetPoint("CENTER", 0, 120)
        prompt:SetFrameStrata("DIALOG")
        prompt:EnableMouse(true)

        local bg = prompt:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.035, 0.04, 0.05, 0.96)

        local ar, ag, ab = ns.GetAccent()
        local line = prompt:CreateTexture(nil, "BORDER")
        line:SetPoint("TOPLEFT")
        line:SetPoint("TOPRIGHT")
        line:SetHeight(2)
        line:SetColorTexture(ar, ag, ab, 1)

        local title = prompt:CreateFontString(nil, "OVERLAY")
        ns.SetFont(title, 16)
        title:SetPoint("TOP", 0, -16)
        title:SetTextColor(ar, ag, ab)
        title:SetText("Aritlok UI")

        prompt.body = prompt:CreateFontString(nil, "OVERLAY")
        ns.SetFont(prompt.body, 12)
        prompt.body:SetPoint("TOP", title, "BOTTOM", 0, -12)
        prompt.body:SetWidth(380)
        prompt.body:SetJustifyH("CENTER")
        prompt.body:SetTextColor(0.9, 0.9, 0.92)

        local reload = MakeButton(prompt, "Reload UI", ar * 0.7, ag * 0.7, ab * 0.7)
        reload:SetPoint("BOTTOMRIGHT", prompt, "BOTTOM", -6, 16)
        -- The reload is the only thing this click does (see the note above).
        reload:SetScript("OnClick", function() ReloadUI() end)

        local later = MakeButton(prompt, "Later", 0.2, 0.21, 0.24)
        later:SetPoint("BOTTOMLEFT", prompt, "BOTTOM", 6, 16)
        later:SetScript("OnClick", function() prompt:Hide() end)
    end
    prompt.body:SetText(message)
    prompt:Show()
end
ns.ShowReloadPrompt = ShowReloadPrompt

-------------------------------------------------------------------------------
--  Preconditions
-------------------------------------------------------------------------------
local function Preflight()
    local eui = _G.EllesmereUI
    if type(eui) ~= "table" then return false, "EllesmereUI is not loaded." end
    if type(_G.EllesmereUIDB) ~= "table" or type(_G.EllesmereUIDB.profiles) ~= "table" then
        return false, "EllesmereUI has no profile data yet. Log in once with it enabled, then try again."
    end
    local needed = { "SaveCurrentAsProfile", "SwitchProfile", "GetActiveProfileName", "GetActiveProfileData" }
    for i = 1, #needed do
        if type(eui[needed[i]]) ~= "function" then
            return false, "this EllesmereUI version has no " .. needed[i] .. "(). Run /aui probe."
        end
    end
    if InCombatLockdown() then
        return false, "you are in combat. Run it again after the fight."
    end
    return true
end

-------------------------------------------------------------------------------
--  Setting writers. Each takes the profile's `addons` table and returns true
--  when that module had settings to change.
-------------------------------------------------------------------------------
local function Sub(parent, key)
    local t = parent[key]
    if type(t) ~= "table" then
        t = {}
        parent[key] = t
    end
    return t
end

-------------------------------------------------------------------------------
--  Layout
--  The numbers are ToxiUI's own default profile (its ElvUI movers, action bar
--  and unit frame tables), which is laid out for a screen 1440 units tall.
--  Everything is scaled by this screen's height / 1440, so the proportions
--  hold on any resolution or UI scale.
--
--   [pet] NAME      100                              42      NAME [tot]
--         [=== player ===]    --- power bar ---    [=== target ===]
--         Lv        12.3K     (cooldown manager)   12.3K        Lv
--         [castbar]                                [castbar]
--
--                              [stance]
--               +------+ [ Bar 1: 12 x 1 ] +------+
--               | Bar4 | [ Bar 2: 12 x 1 ] | Bar5 |
--               | 4x3  | [ Bar 3: 12 x 1 ] | 4x3  |
--   [chat]      ============ bottom bar ============
--
-- The space between the player and target frames is left free on purpose: in
-- ToxiUI that is where the cooldown manager sits, not an action bar.
--
-- EllesmereUI stores a position as a frame's centre, offset from the screen
-- centre in UIParent units (point/relPoint CENTER). A bar with no stored
-- position is drawn at the screen centre, which is why every bar used here
-- gets one. Only layout numbers (screen size, button size) go into the maths.
-------------------------------------------------------------------------------
local GAP = 6

local function Center(x, y)
    return { point = "CENTER", relPoint = "CENTER", x = x, y = y }
end

-- Pixel-perfect UI scale: one UI unit is exactly one screen pixel, which is
-- 768 / the screen's pixel height (0.5333 at 2560 x 1440). EllesmereUI owns
-- the UI scale (it stores and re-applies it at login), so it is set through
-- EllesmereUI's own function; UIParent is not scaled from here. The scale is
-- account-wide in EllesmereUI, not per profile, so the old value is kept for
-- /aui restore. Returns the scale now in force, or nil if it was not changed.
local function ApplyPixelScale()
    local eui = _G.EllesmereUI
    local pp = type(eui) == "table" and eui.PP
    if type(pp) ~= "table" or type(pp.SetUIScale) ~= "function" or type(pp.PixelBestSize) ~= "function" then
        return nil
    end
    local best = pp.PixelBestSize()
    if type(best) ~= "number" or best <= 0 then return nil end
    local current = UIParent:GetScale()
    if type(current) == "number" and math.abs(current - best) > 0.0001 then
        if not ns.db.previousScale then ns.db.previousScale = current end
        pp.SetUIScale(best)
    end
    return best
end

-- scale: the UI scale just set by ApplyPixelScale, if any. UIParent is 768
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
    -- A ToxiUI "units up from the bottom of the screen", as a centre offset.
    function g.Y(fromBottom) return (fromBottom - 720) * k end
    function g.X(v) return v * k end

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
    -- whole stack if the lowest row would touch the bottom bar.
    local lowest = 100 * k - 2 * g.step
    local need = g.reserved + GAP
    local lift = (lowest < need) and (need - lowest) or 0
    g.row1 = g.Y(100) + lift + g.btnH / 2

    -- Chat text area: bottom-left corner, clear of the bottom bar. Shared by
    -- the chat step and the side bar placed next to it.
    g.chatX, g.chatY = 44, g.reserved + g.S(40)
    g.chatW, g.chatH = g.S(520), g.S(200)

    -- Unit frames: 300 x 36, centred 390 left and right, bottom edge 420 up.
    g.frameW, g.frameH = g.S(300), g.S(36)
    g.frameX = g.X(390)
    g.frameY = g.Y(420) + g.frameH / 2
    return g
end

local function WriteUnitFrames(addons, theme, g)
    local uf = addons.EllesmereUIUnitFrames
    if type(uf) ~= "table" then return false end
    local dark = (theme == "dark")

    uf.healthBarTexture = ns.FLAT_KEY      -- our LibSharedMedia texture
    uf.darkTheme = dark

    local units = { "player", "target" }
    for i = 1, #units do
        local u = Sub(uf, units[i])
        u.darkTheme = nil                  -- follow the profile-wide switch above
        u.healthBarTexture = nil
        u.showPortrait = false
        u.healthClassColored = true
        u.bgClassColored = false
        u.customBgColor = { r = 0.05, g = 0.055, b = 0.065 }
        u.healthBarOpacity = 100
        u.gradientEnabled = false          -- the overlays in Shade.lua do this job
        u.borderSize = 1
        u.borderColor = { r = 0, g = 0, b = 0 }
    end
    if not g then return true end

    local S = g.S
    local half = g.frameH / 2
    local p, t = Sub(uf, "player"), Sub(uf, "target")

    for i = 1, 2 do
        local u = (i == 1) and p or t
        u.frameWidth = g.frameW
        u.healthHeight = g.frameH
        u.powerHeight = S(10)
    end

    -- Texts, as in ToxiUI: name above the bar on the outer side, a large
    -- health percentage straddling the top edge on the inner side, level and
    -- current health straddling the bottom edge. These are EllesmereUI's own
    -- text tags; this addon never sees the text.
    local nameSize, bigSize, smallSize = S(18), S(34), S(14)   -- 18, not ToxiUI's 22: the wide font ran names into the number
    local nameY, bigY, lowY = half + S(14), half, -half

    p.leftTextContent, p.leftTextSize, p.leftTextX, p.leftTextY = "name", nameSize, S(6), nameY
    p.rightTextContent, p.rightTextSize, p.rightTextX, p.rightTextY = "perhpnosign", bigSize, -S(12), bigY
    p.leftTextClassColor, p.rightTextClassColor = true, false
    p.extraTextContent, p.extraTextAlign, p.extraTextSize = "level", "left", smallSize
    p.extraTextX, p.extraTextY = S(22), lowY
    p.centerTextContent, p.centerTextSize = "curhpshort", smallSize
    p.centerTextX, p.centerTextY = g.frameW / 2 - S(40), lowY

    t.leftTextContent, t.leftTextSize, t.leftTextX, t.leftTextY = "perhpnosign", bigSize, S(12), bigY
    t.rightTextContent, t.rightTextSize, t.rightTextX, t.rightTextY = "name", nameSize, -S(6), nameY
    t.leftTextClassColor, t.rightTextClassColor = false, true
    t.extraTextContent, t.extraTextAlign, t.extraTextSize = "level", "right", smallSize
    t.extraTextX, t.extraTextY = -S(22), lowY
    t.centerTextContent, t.centerTextSize = "curhpshort", smallSize
    t.centerTextX, t.centerTextY = -(g.frameW / 2 - S(40)), lowY

    -- Target buffs and debuffs above the name and the big number: both sit on
    -- the frame's top edge (buffs from the left, debuffs from the right) and
    -- are lifted clear of the texts. The name's top is about 23 above the bar.
    local auraLift = S(28)
    t.buffAnchor, t.buffOffsetX, t.buffOffsetY = "topleft", 0, auraLift
    t.debuffAnchor, t.debuffOffsetX, t.debuffOffsetY = "topright", 0, auraLift

    -- Power bars detached from the frames. EllesmereUI hangs a detached bar
    -- from the health bar's bottom edge, 15 below it, plus powerX / powerY.
    -- Player: 292 wide, centred on the screen between the two frames.
    p.powerPosition = "detached_bottom"
    p.powerWidth = S(292)
    p.powerX = g.frameX
    p.powerY = 15 + g.frameH + S(10) / 2 + S(5)
    -- Target: 144 wide, sitting on the frame's bottom-left corner.
    t.powerPosition = "detached_bottom"
    t.powerWidth = S(144)
    t.powerX = -g.frameW / 2 + S(12) + S(144) / 2
    t.powerY = 15 + S(10) / 2

    -- Cast bars: 300 x 24, hanging under their frames. The player's own unit
    -- frame cast bar is off by default in EllesmereUI (a separate cast bar in
    -- the middle of the screen is used instead); it is switched on here and
    -- the middle one is switched off in Install().
    p.showPlayerCastbar = true
    p.playerCastbarWidth, p.playerCastbarHeight = g.frameW, S(24)
    t.castbarWidth, t.castbarHeight = g.frameW, S(24)

    -- Small frames: 120 x 18, as in ToxiUI, but centred on the same line as
    -- the player and target bars instead of top-aligned.
    local miniW, miniH = S(120), S(18)
    local minis = { "targettarget", "pet" }
    for i = 1, #minis do
        local m = Sub(uf, minis[i])
        m.frameWidth = miniW
        m.healthHeight = miniH
    end
    local f = Sub(uf, "focus")
    f.frameWidth = g.frameW
    f.healthHeight = g.frameH

    local pos = Sub(uf, "positions")
    local top = g.frameY + half
    local miniX = g.frameX + g.frameW / 2 + S(4) + miniW / 2
    pos.player = Center(-g.frameX, g.frameY)
    pos.target = Center(g.frameX, g.frameY)
    pos.targettarget = Center(miniX, g.frameY)                 -- right of the target, level with it
    pos.pet = Center(-miniX, g.frameY)                         -- left of the player, level with it
    pos.focus = Center(g.frameX, g.frameY - g.frameH - S(70))  -- 70 under the target
    pos.classPower = Center(0, g.Y(463))
    return true
end

-- Moves the player cast bar from the middle of the screen to under the player
-- frame: EllesmereUI's standalone cast bar (Resource Bars module) off, and the
-- unit frame cast bars dropped a little so they clear the level and health
-- texts that straddle the frame's bottom edge. EllesmereUI keeps those cast
-- bars attached to their frames through its unlock anchors, live on the
-- account table and as a snapshot on the profile, so both are updated.
local function WriteCastbars(addons, profile, g)
    if not g then return end
    local rb = addons.EllesmereUIResourceBars
    if type(rb) == "table" then
        Sub(rb, "castBar").enabled = false
    end

    local drop = -g.S(10)
    local stores = {}
    local live = _G.EllesmereUIDB and _G.EllesmereUIDB.unlockAnchors
    if type(live) == "table" then stores[#stores + 1] = live end
    local snapshot = type(profile.unlockLayout) == "table" and profile.unlockLayout.anchors
    if type(snapshot) == "table" then stores[#stores + 1] = snapshot end
    for i = 1, #stores do
        local keys = { "playerCastbar", "targetCastbar" }
        for j = 1, #keys do
            local a = stores[i][keys[j]]
            if type(a) == "table" and a.side == "BOTTOM" then a.offsetY = drop end
        end
    end
end

local function StyleBar(b, g)
    if g then
        b.buttonWidth = g.btnW             -- square base size ...
        b.buttonHeight = g.btnW
        b.buttonShape = "cropped"          -- ... drawn at 80% height, icon cropped not stretched
        b.buttonPadding = g.pad
    end
    b.borderEnabled = true
    b.borderSize = 1
    b.borderColor = { r = 0, g = 0, b = 0, a = 1 }
    b.borderClassColor = false
end

local function ShapeBar(b, rows)
    b.orientation = "horizontal"
    b.numIcons = 12
    b.overrideNumIcons = 12
    b.numRows = rows
    b.overrideNumRows = rows
end

local function Hide(b)
    b.barVisibility = "never"
    b.alwaysHidden = true
end

-- hideXP: the bottom bar shows experience, so the full-width XP and
-- reputation bars go. hideMenu: the bottom bar carries the menu buttons, so
-- Blizzard's micro menu and bag bar go (through EllesmereUI's own visibility
-- setting for them; their position belongs to Edit Mode and is never touched).
local function WriteActionBars(addons, g, hideXP, hideMenu)
    local ab = addons.EllesmereUIActionBars
    if type(ab) ~= "table" then return false end
    local bars = Sub(ab, "bars")
    local positions = Sub(ab, "barPositions")

    for i = 1, #MAIN_BARS do
        StyleBar(Sub(bars, MAIN_BARS[i]), g)
    end

    if hideXP then
        ab.useBlizzardDataBars = false
        Hide(Sub(bars, "XPBar"))
        Hide(Sub(bars, "RepBar"))
    end
    if hideMenu then
        Hide(Sub(bars, "MicroBar"))
        Hide(Sub(bars, "BagBar"))
    end

    if not g then return true end

    -- Three rows at the bottom centre. (ToxiUI uses ElvUI bars 1, 6 and 5,
    -- which are Blizzard's main, bottom-left and bottom-right bars: here
    -- bars 1, 2 and 3.)
    ShapeBar(Sub(bars, "MainBar"), 1); positions.MainBar = Center(0, g.row1)
    ShapeBar(Sub(bars, "Bar2"), 1);    positions.Bar2 = Center(0, g.row1 - g.step)
    ShapeBar(Sub(bars, "Bar3"), 1);    positions.Bar3 = Center(0, g.row1 - 2 * g.step)

    -- A 4 x 3 block on each side, as tall as the three rows. (Blizzard's two
    -- right-hand bars: here bars 4 and 5.)
    local blockW = 4 * g.btnW + 3 * g.pad
    local blockX = g.rowW / 2 + 4 * g.pad + blockW / 2
    local blockY = g.row1 - g.step
    ShapeBar(Sub(bars, "Bar4"), 3);    positions.Bar4 = Center(-blockX, blockY)
    ShapeBar(Sub(bars, "Bar5"), 3);    positions.Bar5 = Center(blockX, blockY)

    -- Stance bar above bar 1.
    positions.StanceBar = Center(0, g.row1 + g.btnH / 2 + g.pad + g.S(16))
    -- The pet bar is exactly as wide as the player health bar: ten buttons
    -- with nine 1-unit gaps, cropped like the main buttons (80% height). It
    -- sits under the player cast bar, which hangs 10 under the frame and is
    -- 24 tall.
    local pet = Sub(bars, "PetBar")
    local petPad = 1
    local petW = (g.frameW - 9 * petPad) / 10
    pet.buttonWidth, pet.buttonHeight = petW, petW
    pet.buttonShape = "cropped"
    pet.buttonPadding = petPad
    pet.orientation = "horizontal"
    pet.numRows, pet.overrideNumRows = 1, 1
    local castbarBottom = g.frameY - g.frameH / 2 - g.S(10) - g.S(24)
    positions.PetBar = Center(-g.frameX, castbarBottom - g.S(6) - petW * 0.8 / 2)

    -- Bar 6: 2 across and 6 down, just right of the chat window, level with its
    -- bottom edge, shown only while the mouse is over it. These are the same
    -- fields EllesmereUI's own "mouseover" visibility mode sets.
    local side = Sub(bars, "Bar6")
    ShapeBar(side, 6)                      -- 12 buttons in 6 rows = 2 per row
    side.enabled = true
    side.barVisibility = "mouseover"
    side.alwaysHidden = false
    side.mouseoverEnabled = true
    side.mouseoverAlpha = 0
    side.combatHideEnabled = false
    side.combatShowEnabled = false
    local sideW = 2 * g.btnW + g.pad
    local sideH = 6 * g.btnH + 5 * g.pad
    positions.Bar6 = Center(
        g.chatX + g.chatW + g.S(14) + sideW / 2 - g.uiW / 2,
        g.chatY + sideH / 2 - g.uiH / 2)

    -- Bars 7-10 have no place in this layout. One that was never positioned
    -- would be drawn at the screen centre, so it is switched off; one you have
    -- placed yourself is left alone. Re-enable them under /eui > Action Bars.
    local spare = { "Bar7", "Bar8", "Bar9", "Bar10" }
    for i = 1, #spare do
        if positions[spare[i]] == nil then
            local b = Sub(bars, spare[i])
            b.enabled = false
            Hide(b)
        end
    end
    return true
end

-- Chat: 520 x 200 in the bottom-left corner, clear of the bottom bar (ToxiUI
-- keeps it 40 above; the gap also leaves room for the chat input line).
-- EllesmereUI stores the position of the chat text area; its panel adds a
-- button column on the left (about 40 wide), so the text area is inset by
-- that much to bring the panel itself into the corner. RETEST: the inset is
-- measured from a screenshot, not read from EllesmereUI.
local function WriteChat(addons, g)
    local mod = addons.EllesmereUIChat
    if type(mod) ~= "table" then return false end
    local chat = Sub(mod, "chat")
    chat.bgAlpha = 0.25                    -- lighter panel, closer to bare text
    -- Messages use the global font (Monaspace) at a small size.
    chat.font = "__global"
    chat.chatFontSize = 11
    -- Tabs keep EllesmereUI's proportional font and tighter side padding. A
    -- tab's width is set by Blizzard's chat dock, not by its label, so a wide
    -- monospaced label gets cut down to "Gen..."; the narrower font fits.
    chat.tabFont = "Expressway"
    chat.tabFontSize = 11
    chat.tabInnerPaddingX = 4
    chat.lockChatSize = true               -- no accidental resizing
    if g then
        chat.chatPosition = { point = "BOTTOMLEFT", relPoint = "BOTTOMLEFT", x = g.chatX, y = g.chatY }
        chat.chatSize = { w = g.chatW, h = g.chatH }     -- ToxiUI's is 450 wide; a little wider here
    end
    return true
end

-- The bottom bar, built by EllesmereUI's DataBars module from its own "Bottom
-- Info Bar" template: icon micro menu, XP, durability, clock, professions,
-- gold, FPS, latency and travel. We only restyle it (no background of its own,
-- so the fade in InfoBar.lua shows through).
--
-- RETEST after an EllesmereUI update: the module publishes its functions only
-- through EllesmereUI._ModuleNS, an internal registry, so every step is
-- checked and a miss falls back to this addon's own bar.
local DATABAR_NAME = "Aritlok Bar"

local function WriteDataBar()
    local eui = _G.EllesmereUI
    local registry = eui._ModuleNS
    local mod = type(registry) == "table" and registry.EllesmereUIDataBars
    if type(mod) ~= "table" or type(mod.CreateBar) ~= "function" or type(mod.GetProfile) ~= "function" then
        return false
    end
    local profile = mod.GetProfile()
    if type(profile) ~= "table" or type(profile.bars) ~= "table" then return false end

    local cfg
    for i = 1, #profile.bars do
        local b = profile.bars[i]
        if type(b) == "table" and b.name == DATABAR_NAME then cfg = b; break end
    end
    if not cfg then
        -- A failure inside EllesmereUI here is an ordinary Lua error, which
        -- pcall does contain.
        local ok, created = pcall(mod.CreateBar, "bottom")
        if not ok or type(created) ~= "table" then return false end
        cfg = created
        cfg.name = DATABAR_NAME
    end

    local bar = ns.db.bar
    cfg.lengthMode = "full"
    cfg.thickness = 30
    cfg.snapEdge = (bar.position == "TOP") and "top" or "bottom"
    cfg.hideBorder = true
    if type(cfg.theme) ~= "table" then cfg.theme = {} end
    cfg.theme.style = "modern"
    cfg.theme.modernColor = { r = 0.035, g = 0.04, b = 0.05, a = 0 }
    if type(cfg.blocks) == "table" then
        for i = 1, #cfg.blocks do
            local block = cfg.blocks[i]
            if type(block) == "table" and block.type == "clock" and type(block.settings) == "table" then
                block.settings.twentyFour = bar.clock24 and true or false
            end
            -- Gold block: silver and copper as well as gold.
            if type(block) == "table" and block.type == "gold" and type(block.settings) == "table" then
                block.settings.showSmall = true
            end
            -- The first menu icon was cut off by the screen edge.
            if type(block) == "table" and block.type == "micromenu" then
                block.xOff = 10
                block.contentGapL = 16
                -- Room after the icons for our own, longer XP bar.
                if bar.showXP then
                    local length = type(bar.xpLength) == "number" and bar.xpLength or 320
                    block.contentGapR = 40 + length + 40
                end
            end
        end
        -- EllesmereUI's XP block is only as long as its label plus 40 and has
        -- no length setting, so it is taken out in favour of the bar drawn in
        -- InfoBar.lua. (Walk backwards: entries are removed while iterating.)
        if bar.showXP then
            for i = #cfg.blocks, 1, -1 do
                local block = cfg.blocks[i]
                if type(block) == "table" and block.type == "xprep" then
                    table.remove(cfg.blocks, i)
                end
            end
            bar.xpLong = true
        end
    end
    return true
end

-- Cooldown manager (EllesmereUI's, which shows Blizzard's cooldown manager
-- spells): three horizontal rows centred between the player and target
-- frames, as in ToxiUI. EllesmereUI had copied Blizzard's default vertical
-- layout, which put a column of icons through the power bar.
--   buffs       above the power bar
--   cooldowns   directly under the power bar
--   utility     under the cooldowns
local function WriteCooldowns(addons, g)
    local mod = addons.EllesmereUICooldownManager
    if type(mod) ~= "table" or not g then return false end
    local bars = type(mod.cdmBars) == "table" and mod.cdmBars.bars
    if type(bars) ~= "table" then return false end
    local positions = Sub(mod, "cdmBarPositions")
    local S = g.S

    local powerBottom = g.Y(446)                  -- player power bar: 10 tall, centred 451 up
    local size = { cooldowns = S(40), utility = S(30), buffs = S(32) }
    local y = {}
    y.cooldowns = powerBottom - S(6) - size.cooldowns / 2
    y.utility = y.cooldowns - size.cooldowns / 2 - S(4) - size.utility / 2
    y.buffs = g.Y(470) + S(8) + size.buffs / 2

    local placed = false
    for i = 1, #bars do
        local b = bars[i]
        local key = type(b) == "table" and b.key
        if key and size[key] then
            b.verticalOrientation = false
            b.growDirection = "CENTER"
            b.numRows = 1
            b.iconSize = size[key]
            b.spacing = S(2)
            positions[key] = Center(0, y[key])
            placed = true
        end
    end
    return placed
end

-- Chat windows that float on their own (the Loot / Trade window) are docked
-- into the main chat window as tabs. This calls Blizzard's own docking
-- function once, from the installer click, out of combat; chat windows are
-- not protected frames, and the reload that follows the install starts clean.
-- RETEST on a new build. Returns how many were docked.
local function DockChatWindows()
    local dock = _G.GENERAL_CHAT_DOCK
    if type(FCF_DockFrame) ~= "function" or type(dock) ~= "table" or type(dock.DOCKED_CHAT_FRAMES) ~= "table" then
        return 0
    end
    local count = 0
    for i = 3, (NUM_CHAT_WINDOWS or 10) do
        local frame = _G["ChatFrame" .. i]
        if type(frame) == "table" and frame.IsShown and frame:IsShown()
            and not frame.isDocked and not frame.isTemporary then
            FCF_DockFrame(frame, #dock.DOCKED_CHAT_FRAMES + 1, false)
            count = count + 1
        end
    end
    return count
end

-- Minimap: top-right corner, 4 in from each edge (ToxiUI's MinimapMover).
local function WriteMinimap(addons, g)
    local mod = addons.EllesmereUIMinimap
    if type(mod) ~= "table" or not g then return false end
    local inset = g.S(4)
    Sub(mod, "minimap").position = { point = "TOPRIGHT", relPoint = "TOPRIGHT", x = -inset, y = -inset }
    return true
end

-- Right edge, top to bottom: minimap, quest tracker, tooltip, damage meter.
-- Sizes and spots are the ones you set by hand in unlock mode (measured on a
-- 2560 x 1440 screen), kept flush with the right edge and scaled like the rest.
--   Quest tracker   301 x 398, top edge 346 below the top of the screen
--   Damage meter    394 x 241, sitting on the bottom bar, split into a
--                   damage window beside a healing window
--   Tooltip         its anchor box directly above the meters
-- Returns the list of what was placed.
local function WriteRightSide(addons, profile, g)
    local placed = {}
    if not g then return placed end
    local S = g.S

    -- Quest tracker (EllesmereUI's custom tracker): a point, a width and a
    -- maximum height.
    local qt = addons.EllesmereUIQuestTracker
    if type(qt) == "table" then
        local t = Sub(qt, "questTracker")
        t.customPos = { point = "TOPRIGHT", relPoint = "TOPRIGHT", x = 0, y = -S(346) }
        t.customWidth = S(301)
        t.customMaxHeight = S(398)
        placed[#placed + 1] = "quest tracker"
    end

    local dmW, dmH = S(394), S(241)
    local dmBottom = g.reserved + 3
    local dm = addons.EllesmereUIDamageMeters
    if type(dm) == "table" then
        -- Two windows sharing that area side by side: damage done (which also
        -- shows per-second) on the left, healing done on the right. A window
        -- is stored as its top-left corner measured from the bottom-left
        -- corner of the screen.
        local types = Enum and Enum.DamageMeterType
        local damageType = (types and types.DamageDone) or 0
        local healingType = (types and types.HealingDone) or 2
        local gap = 2
        local leftW = math.floor((dmW - gap) / 2)
        local rightW = dmW - gap - leftW
        local windows = Sub(Sub(dm, "dm"), "windows")
        dm.dm.windowCount = 2

        local damage = Sub(windows, 1)
        damage.width, damage.height = leftW, dmH
        damage.position = { x = g.uiW - dmW, y = dmBottom + dmH }
        damage.curDMType = damageType
        damage.locked = true               -- no accidental dragging or closing

        local healing = Sub(windows, 2)
        healing.width, healing.height = rightW, dmH
        healing.position = { x = g.uiW - rightW, y = dmBottom + dmH }
        healing.curDMType = healingType
        healing.locked = true

        -- Look: no black window or header box, just the bars over the game
        -- world (as ToxiUI's meter), with our flat bar texture and the header
        -- buttons shown only on mouse-over. EllesmereUI keeps a second copy of
        -- some of these per style ("eui" is the flat one), so both are set.
        local look = dm.dm
        look.bgAlpha = 0
        look.hdrBgAlpha = 0
        look.hdrMouseoverIcons = true
        look.barBgAlpha = 0.35
        look.barTexture = ns.FLAT_KEY
        local slot = type(look._styleSlots) == "table" and look._styleSlots.eui
        if type(slot) == "table" then
            slot.bgAlpha = 0
            slot.barBgAlpha = 0.35
            slot.barTexture = ns.FLAT_KEY
        end
        placed[#placed + 1] = "damage meter"
    end

    -- Tooltip fixed position: stored on the profile itself, as the centre of
    -- its anchor box offset from the screen centre.
    local boxW, boxH = 280, 165            -- EllesmereUI's fixed anchor box, not scaled
    profile.tooltipFixedPos = {
        centerX = g.uiW / 2 - boxW / 2,
        centerY = -g.uiH / 2 + dmBottom + dmH + S(4) + boxH / 2,     -- directly above the meters
    }
    placed[#placed + 1] = "tooltip"
    return placed
end

-------------------------------------------------------------------------------
--  Install / restore
-------------------------------------------------------------------------------
-- quiet = true: the caller (the installer window) offers the reload itself.
-- Returns true, or false and the reason.
function ns.Install(theme, quiet)
    local db = ns.db
    if theme ~= "dark" and theme ~= "gradient" then theme = db.theme end
    if theme ~= "dark" then theme = "gradient" end

    local ok, reason = Preflight()
    if not ok then
        ns.Print("cannot install: " .. reason)
        return false, reason
    end

    local eui = _G.EllesmereUI
    local current = eui.GetActiveProfileName()
    if current ~= PROFILE_NAME then
        db.previousProfile = current or false
        if _G.EllesmereUIDB.profiles[PROFILE_NAME] then
            eui.SwitchProfile(PROFILE_NAME)
        else
            eui.SaveCurrentAsProfile(PROFILE_NAME)   -- copies the active profile, then switches
        end
    end

    -- Never write into a profile other than our own copy.
    if eui.GetActiveProfileName() ~= PROFILE_NAME then
        local reason = "EllesmereUI did not switch to the " .. PROFILE_NAME .. " profile. Nothing was changed."
        ns.Print("cannot install: " .. reason)
        return false, reason
    end
    local profile = eui.GetActiveProfileData()
    if type(profile) ~= "table" then
        local reason = "EllesmereUI returned no profile data. Nothing was changed."
        ns.Print("cannot install: " .. reason)
        return false, reason
    end
    local addons = Sub(profile, "addons")

    local done, skipped = {}, {}
    local want = db.install

    if want.style then
        -- The flat "eui" look for every module; on Forever a fresh install
        -- starts on the bronze "forever" look instead. Latches at reload.
        if eui.ApplyFirstInstallLook and eui.ApplyFirstInstallLook("eui") then
            done[#done + 1] = "flat style"
        else
            skipped[#skipped + 1] = "style (EllesmereUI options addon unavailable)"
        end
    end

    -- Font, after the style step (which sets the style's own default font).
    -- EllesmereUI stores a font by name and resolves LibSharedMedia names, so
    -- the name registered in Media.lua is all it needs. Applies at reload.
    if want.font then
        if eui.GetFontsDB then
            eui.GetFontsDB().global = ns.FONT_NAME
            if type(profile.fonts) == "table" then profile.fonts.global = ns.FONT_NAME end
            if eui.InvalidateFontCache then eui.InvalidateFontCache() end
            done[#done + 1] = "font (" .. ns.FONT_NAME .. ")"
        else
            skipped[#skipped + 1] = "font"
        end
    end

    -- Bottom bar first: which bar is used decides how much room it takes.
    db.bar.mode = "own"
    if want.dataBar and db.bar.enabled then
        if WriteDataBar() then
            db.bar.mode = "eui"
            done[#done + 1] = "bottom bar (EllesmereUI DataBars)"
        else
            skipped[#skipped + 1] = "EllesmereUI DataBars bar (module not loaded; using the built-in bar)"
        end
    end
    local barOn = db.bar.enabled
    local hideXP = barOn and (db.bar.mode == "eui" or db.bar.showXP)
    local hideMenu = barOn and (db.bar.mode == "eui" or db.bar.micro)

    local scale
    if want.scale then
        scale = ApplyPixelScale()
        if scale then done[#done + 1] = string.format("UI scale %.4f", scale)
        else skipped[#skipped + 1] = "UI scale (EllesmereUI's scale function not found)" end
    end

    local g = Geometry(scale)
    if want.unitFrames then
        if WriteUnitFrames(addons, theme, g) then done[#done + 1] = "unit frames"
        else skipped[#skipped + 1] = "unit frames (module has no settings in this profile)" end
        if WriteCooldowns(addons, g) then done[#done + 1] = "cooldown manager" end
        WriteCastbars(addons, profile, g)
    end
    if want.actionBars then
        if WriteActionBars(addons, g, hideXP, hideMenu) then done[#done + 1] = "action bars"
        else skipped[#skipped + 1] = "action bars (module has no settings in this profile)" end
    end
    if want.chat then
        if WriteChat(addons, g) then done[#done + 1] = "chat" end
        local docked = DockChatWindows()
        if docked > 0 then done[#done + 1] = docked .. " chat window(s) docked as tabs" end
    end
    if want.minimap then
        if WriteMinimap(addons, g) then done[#done + 1] = "minimap" end
    end
    if want.rightSide then
        local placed = WriteRightSide(addons, profile, g)
        for i = 1, #placed do done[#done + 1] = placed[i] end
    end
    if want.accent then
        -- The accent is what EllesmereUI's quest tracker headers, damage meter
        -- title and bars, chat underline and DataBar labels are all coloured
        -- with, so one setting keeps them the same colour.
        if want.accentClass and eui.SetActiveProfileAccent and eui.RefreshAccent then
            eui.SetActiveProfileAccent(nil, true)      -- useClass = true, on this profile
            eui.RefreshAccent()
            done[#done + 1] = "class-colour accent"
        elseif eui.SetAccentColor then
            local a = ns.DEFAULT_ACCENT
            eui.SetAccentColor(a.r, a.g, a.b)
            done[#done + 1] = "accent colour"
        else
            skipped[#skipped + 1] = "accent colour"
        end
    end

    db.theme = theme
    db.installed = true
    ns.RefreshShades()
    ns.ApplyInfoBar()

    ns.Print("installed the " .. theme .. " theme into EllesmereUI profile \"" .. PROFILE_NAME .. "\": "
        .. (#done > 0 and table.concat(done, ", ") or "nothing") .. ".")
    if #skipped > 0 then
        ns.Print("skipped: " .. table.concat(skipped, "; ") .. ".")
    end
    if not quiet then
        ShowReloadPrompt("The " .. theme .. " theme is written to the EllesmereUI profile \"" .. PROFILE_NAME
            .. "\".|n|nReload the UI to apply it.")
    end
    return true, (#skipped > 0) and ("Skipped: " .. table.concat(skipped, "; ") .. ".") or nil
end

function ns.Restore()
    local db = ns.db
    local ok, reason = Preflight()
    if not ok then
        ns.Print("cannot restore: " .. reason)
        return false
    end

    local eui = _G.EllesmereUI
    local previous = db.previousProfile
    if type(previous) ~= "string" or not _G.EllesmereUIDB.profiles[previous] then
        ns.Print("no earlier EllesmereUI profile is recorded. Pick one under /eui > Profiles.")
        return false
    end
    if eui.GetActiveProfileName() == previous then
        ns.Print("EllesmereUI is already on \"" .. previous .. "\".")
        return false
    end

    eui.SwitchProfile(previous)
    if type(db.previousScale) == "number" and type(eui.PP) == "table" and eui.PP.SetUIScale then
        eui.PP.SetUIScale(db.previousScale)
        db.previousScale = false
    end
    db.installed = false
    ns.Print("switched EllesmereUI back to \"" .. previous .. "\". The \"" .. PROFILE_NAME
        .. "\" profile is kept; delete it under /eui > Profiles if you no longer want it.")
    ShowReloadPrompt("EllesmereUI is back on the \"" .. previous .. "\" profile.|n|nReload the UI to apply it.")
    return true
end
