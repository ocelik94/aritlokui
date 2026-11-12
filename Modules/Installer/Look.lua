local addonName, ns = ...

-------------------------------------------------------------------------------
--  Installer steps: style, font, accent color, UI scale and the bag view.
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
