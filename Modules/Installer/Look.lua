local addonName, ns = ...

-------------------------------------------------------------------------------
--  Installer steps: style, font, accent color, UI scale, the bag view and
--  the window color.
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
-- setting keeps them the same color: the player's class color.
I.AddStep({
    order = 30,
    option = "accent",
    run = function(ctx)
        local eui = ctx.eui
        if eui.SetActiveProfileAccent and eui.RefreshAccent then
            eui.SetActiveProfileAccent(nil, true) -- useClass = true, on this profile
            eui.RefreshAccent()
            ctx:Done("class-color accent")
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
    "charsheet", "inspect", "lfg", "greatvault", "collections", "playerspells", "adventureguide",
    "professionsbook", "guild", "calendar", "achievements", "mail", "catalyst", "socket", "itemupgrade",
    "loot", "loottoast", "bnettoast", "lootroll", "loothistory", "groupinvite", "readycheck", "micromenu",
    "housing", "professions", "worldmap", "dressup", "transmog", "merchant", "auctionhouse", "macros",
    "settings", "addonlist", "craftorders", "trainer", "gossip", "quest", "inspectrecipe", "delves",
    "socialui", "queuestatus", "delvepicker", "playerchoice", "trade", "bagbar", "legacysystem",
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
