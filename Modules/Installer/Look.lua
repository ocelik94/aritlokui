local addonName, ns = ...

-------------------------------------------------------------------------------
--  Installer steps: style, font, accent color, UI scale, the bag view, the
--  window color and the frame shape.
--  These run before the layout steps: the scale decides the screen size the
--  layout is computed for.
-------------------------------------------------------------------------------

local I = ns.Installer

-- The flat "eui" look for every module; on Forever a fresh install starts on
-- the bronze "forever" look instead. Latches at reload.
I.AddStep({
    order = 10,
    option = "style",
    run = function(ctx)
        local eui = ctx.eui
        if eui.ApplyFirstInstallLook and eui.ApplyFirstInstallLook("eui") then
            ctx:Done("flat style")
        else
            ctx:Skip("style (EllesmereUI options addon unavailable)")
        end
    end,
})

-- Font, after the style step (which sets the style's own default font).
-- EllesmereUI stores a font by name and resolves LibSharedMedia names, so the
-- name registered in Media.lua is all it needs. Applies at reload.
I.AddStep({
    order = 20,
    option = "font",
    run = function(ctx)
        local eui = ctx.eui
        if not eui.GetFontsDB then
            ctx:Skip("font")
            return
        end
        eui.GetFontsDB().global = ns.FONT_NAME
        if type(ctx.profile.fonts) == "table" then ctx.profile.fonts.global = ns.FONT_NAME end
        if eui.InvalidateFontCache then eui.InvalidateFontCache() end
        ctx:Done("font (%s)", ns.FONT_NAME)
    end,
})

-- The accent is what EllesmereUI's quest tracker headers, damage meter title
-- and bars, chat underline and DataBar labels are all colored with, so one
-- setting keeps them the same color: the player's class color, or one fixed
-- color for every character (AritlokUIDB.accent, set on the settings page).
--
-- EllesmereUI.SetActiveProfileAccent(custom, useClass) stores the choice in
-- the ACTIVE profile (euiAccent.custom / euiAccent.useClass; useClass wins
-- over custom, so it is passed as false for a fixed color) and applies
-- nothing by itself; RefreshAccent repaints live. Read from 9.8.4,
-- EllesmereUI_UICore.lua.
function I.ApplyAccent(eui)
    if type(eui) ~= "table" or not (eui.SetActiveProfileAccent and eui.RefreshAccent) then return false end
    local accent = ns.db.accent
    if accent.mode == "fixed" and type(accent.color) == "table" then
        local c = accent.color
        eui.SetActiveProfileAccent({ r = c.r, g = c.g, b = c.b }, false)
    else
        eui.SetActiveProfileAccent(nil, true)
    end
    eui.RefreshAccent()
    return true
end

I.AddStep({
    order = 30,
    -- Always: the choice itself (class or fixed) is on the Theme page.
    option = nil,
    run = function(ctx)
        if I.ApplyAccent(ctx.eui) then
            ctx:Done(ns.db.accent.mode == "fixed" and "fixed accent color" or "class-color accent")
        else
            ctx:Skip("accent color")
        end
    end,
})

-- Pixel-perfect UI scale: one UI unit is exactly one screen pixel, which is
-- 768 / the screen's pixel height (0.5333 at 2560 x 1440). EllesmereUI owns
-- the UI scale (it stores and re-applies it at login), so it is set through
-- EllesmereUI's own function; UIParent is not scaled from here. The scale is
-- account-wide in EllesmereUI, not per profile.
I.AddStep({
    order = 50,
    option = "scale",
    run = function(ctx)
        local pp = ctx.eui.PP
        if type(pp) ~= "table" or type(pp.SetUIScale) ~= "function" or type(pp.PixelBestSize) ~= "function" then
            ctx:Skip("UI scale (EllesmereUI's scale function not found)")
            return
        end
        local best = pp.PixelBestSize()
        if type(best) ~= "number" or best <= 0 then
            ctx:Skip("UI scale")
            return
        end
        local current = UIParent:GetScale()
        if type(current) == "number" and math.abs(current - best) > 0.0001 then pp.SetUIScale(best) end
        ctx.scale = best
        ctx:Done("UI scale %.4f", best)
    end,
})

-- Bags in EllesmereUI's compact view, opening as one bag. The view is one of
-- three display modes of its Bags module ("grid", "list", "compact") and
-- applies at reload; the default bag type is "all", "onebag" or "multibag".
I.AddStep({
    order = 60,
    option = "bags",
    run = function(ctx)
        -- The module's settings table is only there once it has saved
        -- something; `_bagsDB` is set by the module itself when it loads
        -- (EllesmereUIBags_DB.lua), so it tells a loaded module apart.
        local bags = ctx.addons.EllesmereUIBags
        if type(bags) ~= "table" then
            if not ctx.eui._bagsDB then
                ctx:Skip("compact bags (EllesmereUI Bags is not loaded)")
                return
            end
            bags = I.Sub(ctx.addons, "EllesmereUIBags")
        end
        bags.bagDisplayMode = "compact"
        bags.bagDefaultBagType = "onebag"
        ctx:Done("compact bags")
    end,
})

-------------------------------------------------------------------------------
--  One background color (ns.PANEL) for every window: the bags, every Blizzard
--  window EllesmereUI skins, and tooltips.
--
--  Windows: EllesmereUI skins each one in one of two styles, its textured
--  "EllesmereUI" look or a flat "Modern" one, and every Modern window takes
--  one shared color. So each skinned window is switched to Modern and that
--  color is set. A window set to Blizzard's own look, or with its skin off,
--  is left alone.
--
--  These window and tooltip settings are account-wide in EllesmereUI (the top
--  level of EllesmereUIDB, shared by every profile), like the UI scale; the
--  bag settings are synced across profiles by EllesmereUI.
--
--  RETEST after an EllesmereUI update (read from 9.8.4): the window keys are
--  WINDOW_ENABLE_KEYS in EllesmereUIBlizzardSkin.lua, which it does not
--  publish, so they are copied here. A key missing from this list just keeps
--  its current look; one that no longer exists is ignored by EllesmereUI.
--  Settings: blizzWindowSkinStyles, blizzWindowModernDefault (WindowEngine),
--  tooltipBgColor / tooltipBgOpacity (0-1, EllesmereUI.lua GetTooltipBg),
--  bagBgColor / bagBgOpacity (0-100, EUI_Bags_Shared.lua).
-------------------------------------------------------------------------------
local WINDOWS = {
    "charsheet",
    "inspect",
    "lfg",
    "greatvault",
    "collections",
    "playerspells",
    "adventureguide",
    "professionsbook",
    "guild",
    "calendar",
    "achievements",
    "mail",
    "catalyst",
    "socket",
    "itemupgrade",
    "loot",
    "loottoast",
    "bnettoast",
    "lootroll",
    "loothistory",
    "groupinvite",
    "readycheck",
    "micromenu",
    "housing",
    "professions",
    "worldmap",
    "dressup",
    "transmog",
    "merchant",
    "auctionhouse",
    "macros",
    "settings",
    "addonlist",
    "craftorders",
    "trainer",
    "gossip",
    "quest",
    "inspectrecipe",
    "delves",
    "socialui",
    "queuestatus",
    "delvepicker",
    "playerchoice",
    "trade",
    "bagbar",
    "legacysystem",
}

local function Color(a) return { r = ns.PANEL.r, g = ns.PANEL.g, b = ns.PANEL.b, a = a } end

I.AddStep({
    order = 70,
    option = "panels",
    run = function(ctx)
        local db = _G.EllesmereUIDB
        if type(db) ~= "table" then
            ctx:Skip("window color")
            return
        end

        if type(db.blizzWindowSkinStyles) ~= "table" then db.blizzWindowSkinStyles = {} end
        local styles = db.blizzWindowSkinStyles
        for i = 1, #WINDOWS do
            local key = WINDOWS[i]
            if styles[key] ~= "blizzard" then styles[key] = "modern" end
        end
        db.blizzWindowModernDefault = Color(ns.PANEL.a)

        db.tooltipBgColor = Color(1)
        db.tooltipBgOpacity = ns.PANEL.a

        -- Bags: a textured backdrop with a tint on top. A fully opaque tint
        -- hides the texture, so the window reads as the flat color.
        local bags = ctx.addons.EllesmereUIBags
        if type(bags) ~= "table" and ctx.eui._bagsDB then bags = I.Sub(ctx.addons, "EllesmereUIBags") end
        if type(bags) == "table" then
            bags.bagBgColor = Color(1)
            bags.bagBgOpacity = math.floor(ns.PANEL.a * 100 + 0.5)
        end
        ctx:Done("one window color")
    end,
})

-------------------------------------------------------------------------------
--  Frame shape (AritlokUIDB.install.shape, I.shapes): the corners of the unit
--  frames, party and raid frames and nameplates. EllesmereUI rounds them
--  itself (EllesmereUI_RoundedCorners.lua); this only sets its two keys per
--  frame type. Rounding needs a Solid, Glow or Shadow border, and Solid is
--  what these modules default to.
--
--  RETEST after an EllesmereUI update (read from 9.8.4): cornerRadius (0-16)
--  and cornerMask (bits 1 TL, 2 TR, 4 BL, 8 BR) on each unit's table in
--  EllesmereUIUnitFrames (EUI_UnitFrames_Reload.lua; boss and the small
--  frames always take theirs from a donor unit: their lookSource, else focus,
--  then target, then player, EUI_UnitFrames_Layout.lua UF_MiniDonorKey), flat in
--  EllesmereUIRaidFrames (party follows raid) and EllesmereUINameplates
--  (health and cast bar).
-------------------------------------------------------------------------------
local SHAPE_UNITS = { "player", "target", "focus", "targettarget", "focustarget", "pet", "boss" }

-- Frames on the right of the screen get the leaf mirrored (top right and
-- bottom left), so the player and target frames face each other across the
-- center. Shapes that are the same both ways (rectangle, rounded) are not
-- changed by this.
local MIRRORED = { target = true, targettarget = true, focus = true, focustarget = true }

-- The small frames' donor, so each takes its corners from the frame on its
-- own side: left unset, the pet would copy the focus frame's mirrored leaf.
-- A Copy Look From the player chose is kept.
local DONOR = { pet = "player", targettarget = "target", focustarget = "focus" }

local function Mirror(corners)
    if corners == 9 then return 6 end -- TL + BR -> TR + BL
    return corners
end

function I.ShapeFor(key)
    for i = 1, #I.shapes do
        if I.shapes[i].key == key then return I.shapes[i] end
    end
    return I.shapes[2] -- leaf
end

local function SetCorners(t, radius, corners)
    t.cornerRadius = radius
    if radius > 0 then t.cornerMask = corners end
end

I.AddStep({
    order = 65,
    option = nil,
    run = function(ctx)
        local shape = I.ShapeFor(ctx.want.shape)
        local g = ctx:Geometry()
        local radius = 0
        if shape.radius > 0 then
            radius = g and g.S(shape.radius) or shape.radius
            if radius > 16 then radius = 16 end
        end
        local done = false
        local uf = ctx.addons.EllesmereUIUnitFrames
        if type(uf) == "table" then
            for i = 1, #SHAPE_UNITS do
                local unit = SHAPE_UNITS[i]
                local corners = MIRRORED[unit] and Mirror(shape.corners) or shape.corners
                local t = I.Sub(uf, unit)
                SetCorners(t, radius, corners)
                if DONOR[unit] and t.lookSource == nil then t.lookSource = DONOR[unit] end
            end
            done = true
        end
        for _, folder in ipairs({ "EllesmereUIRaidFrames", "EllesmereUINameplates" }) do
            local t = ctx.addons[folder]
            if type(t) == "table" then
                SetCorners(t, radius, shape.corners)
                done = true
            end
        end
        if done then
            ctx:Done("frame shape (%s)", ns.L[shape.title])
        else
            ctx:Skip("frame shape")
        end
    end,
})
