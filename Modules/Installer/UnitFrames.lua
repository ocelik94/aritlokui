local addonName, ns = ...

-------------------------------------------------------------------------------
--  Installer step: unit frames, cast bars and the cooldown manager rows.
--  All of these are EllesmereUI settings; this addon never sees unit health,
--  power or names.
-------------------------------------------------------------------------------

local I = ns.Installer
local Sub, Center = I.Sub, I.Center

local function WriteUnitFrames(ctx, g)
    local uf = ctx.addons.EllesmereUIUnitFrames
    if type(uf) ~= "table" then return false end
    local dark = (ctx.theme == "dark")

    uf.healthBarTexture = ns.FLAT_KEY -- our LibSharedMedia texture
    uf.darkTheme = dark
    -- EllesmereUI lifts every cast bar to the HIGH strata by default, which
    -- draws it over windows such as the bags. Off: cast bars stay in the unit
    -- frames' own strata ("Raise Cast Bar Strata (All)" in its options).
    uf.raiseCastbarStrata = false

    local units = { "player", "target" }
    for i = 1, #units do
        local u = Sub(uf, units[i])
        u.darkTheme = nil -- follow the profile-wide switch above
        u.healthBarTexture = nil
        u.showPortrait = false
        u.healthClassColored = true
        u.bgClassColored = false
        u.customBgColor = { r = 0.05, g = 0.055, b = 0.065 }
        u.healthBarOpacity = 100
        u.gradientEnabled = false -- the overlays in Shade.lua do this job
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
    -- text tags. The name is 15, not ToxiUI's 22: in the wide font a two-word name
    -- still ran into the number at 18.
    local nameSize, bigSize, smallSize = S(15), S(34), S(14)
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
    -- Player: 292 wide, centerd on the screen between the two frames.
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
    -- the middle one is switched off in WriteCastbars.
    p.showPlayerCastbar = true
    p.playerCastbarWidth, p.playerCastbarHeight = g.frameW, S(24)
    t.castbarWidth, t.castbarHeight = g.frameW, S(24)

    -- Small frames: 120 x 18, as in ToxiUI, but centerd on the same line as
    -- the player and target bars instead of top-aligned.
    local miniW, miniH = S(120), S(18)
    local minis = { "targettarget", "pet" }
    for i = 1, #minis do
        local m = Sub(uf, minis[i])
        m.frameWidth = miniW
        m.healthHeight = miniH
    end
    -- The pet's health bar takes the player's class color (EllesmereUI's own
    -- option for the pet frame) instead of the green of a friendly unit;
    -- Shade.lua darkens it a little so it still reads as a different frame.
    Sub(uf, "pet").healthClassColored = true

    local f = Sub(uf, "focus")
    f.frameWidth = g.frameW
    f.healthHeight = g.frameH

    local pos = Sub(uf, "positions")
    local miniX = g.frameX + g.frameW / 2 + S(4) + miniW / 2
    pos.player = Center(-g.frameX, g.frameY)
    pos.target = Center(g.frameX, g.frameY)
    pos.targettarget = Center(miniX, g.frameY) -- right of the target, level with it
    pos.pet = Center(-miniX, g.frameY) -- left of the player, level with it
    pos.focus = Center(g.frameX, g.frameY - g.frameH - S(70)) -- 70 under the target
    pos.classPower = Center(0, g.Y(463))
    return true
end

-- Moves the player cast bar from the middle of the screen to under the player
-- frame: EllesmereUI's standalone cast bar (Resource Bars module) off, and the
-- unit frame cast bars dropped a little so they clear the level and health
-- texts that straddle the frame's bottom edge. EllesmereUI keeps those cast
-- bars attached to their frames through its unlock anchors, live on the
-- account table and as a snapshot on the profile, so both are updated.
local function WriteCastbars(ctx, g)
    local rb = ctx.addons.EllesmereUIResourceBars
    if type(rb) == "table" then Sub(rb, "castBar").enabled = false end

    local drop = -g.S(10)
    local stores = {}
    local live = _G.EllesmereUIDB and _G.EllesmereUIDB.unlockAnchors
    if type(live) == "table" then stores[#stores + 1] = live end
    local snapshot = type(ctx.profile.unlockLayout) == "table" and ctx.profile.unlockLayout.anchors
    if type(snapshot) == "table" then stores[#stores + 1] = snapshot end
    for i = 1, #stores do
        local keys = { "playerCastbar", "targetCastbar" }
        for j = 1, #keys do
            local a = stores[i][keys[j]]
            if type(a) == "table" and a.side == "BOTTOM" then a.offsetY = drop end
        end
    end
end

-- Cooldown manager (EllesmereUI's, which shows Blizzard's cooldown manager
-- spells): three horizontal rows centerd between the player and target
-- frames, as in ToxiUI. EllesmereUI copies Blizzard's default vertical
-- layout, which puts a column of icons through the power bar.
--   buffs       above the power bar
--   cooldowns   directly under the power bar
--   utility     under the cooldowns
local function WriteCooldowns(ctx, g)
    local mod = ctx.addons.EllesmereUICooldownManager
    if type(mod) ~= "table" then return false end
    local bars = type(mod.cdmBars) == "table" and mod.cdmBars.bars
    if type(bars) ~= "table" then return false end
    local positions = Sub(mod, "cdmBarPositions")
    local S = g.S

    local powerBottom = g.Y(446) -- player power bar: 10 tall, centerd 451 up
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

I.AddStep({
    order = 100,
    option = "unitFrames",
    run = function(ctx)
        local g = ctx:Geometry()
        if WriteUnitFrames(ctx, g) then
            ctx:Done("unit frames")
        else
            ctx:Skip("unit frames (module has no settings in this profile)")
        end
        if g then
            WriteCastbars(ctx, g)
            if WriteCooldowns(ctx, g) then ctx:Done("cooldown manager") end
        end
    end,
})
