local addonName, ns = ...

-------------------------------------------------------------------------------
--  Installer step: the menu bar.
--  Built by EllesmereUI's DataBars module from its own "Bottom Info Bar"
--  template: icon micro menu, durability, clock, professions, gold, FPS,
--  latency and travel. It is only restyled here (no background of its own, so
--  the fade in InfoBar.lua shows through), and its fixed-length XP block is
--  swapped for the longer bar InfoBar.lua draws.
--
--  RETEST after an EllesmereUI update: the module publishes its functions
--  only through EllesmereUI._ModuleNS, an internal registry, so every step is
--  checked and a miss just leaves the menu bar out.
-------------------------------------------------------------------------------

local I = ns.Installer
local DATABAR_NAME = "Aritlok Bar"

local function Write(ctx)
    local registry = ctx.eui._ModuleNS
    local mod = type(registry) == "table" and registry.EllesmereUIDataBars
    if type(mod) ~= "table" or type(mod.CreateBar) ~= "function" or type(mod.GetProfile) ~= "function" then return false end
    local profile = mod.GetProfile()
    if type(profile) ~= "table" or type(profile.bars) ~= "table" then return false end

    local cfg
    for i = 1, #profile.bars do
        local b = profile.bars[i]
        if type(b) == "table" and b.name == DATABAR_NAME then
            cfg = b
            break
        end
    end
    if not cfg then
        -- A failure inside EllesmereUI here is an ordinary Lua error, which
        -- pcall does contain.
        local ok, created = pcall(mod.CreateBar, "bottom")
        if not ok or type(created) ~= "table" then return false end
        cfg = created
        cfg.name = DATABAR_NAME
    end

    local bar = ctx.db.bar
    cfg.lengthMode = "full"
    cfg.thickness = ns.InfoBarHeight()
    cfg.snapEdge = (bar.position == "TOP") and "top" or "bottom"
    cfg.hideBorder = true
    if type(cfg.theme) ~= "table" then cfg.theme = {} end
    cfg.theme.style = "modern"
    cfg.theme.modernColor = { r = 0.035, g = 0.04, b = 0.05, a = 0 }

    if type(cfg.blocks) == "table" then
        for i = 1, #cfg.blocks do
            local block = cfg.blocks[i]
            if type(block) == "table" then
                local settings = type(block.settings) == "table" and block.settings
                if block.type == "clock" and settings then settings.twentyFour = bar.clock24 and true or false end
                -- Silver and copper as well as gold.
                if block.type == "gold" and settings then settings.showSmall = true end
                if block.type == "micromenu" then
                    -- The first menu icon was cut off by the screen edge.
                    block.xOff = 10
                    block.contentGapL = 16
                    -- Room after the icons for our own, longer XP bar.
                    if bar.showXP then
                        local length = type(bar.xpLength) == "number" and bar.xpLength or 320
                        block.contentGapR = 40 + length + 40
                    end
                end
            end
        end
        -- EllesmereUI's XP block is only as long as its label plus 40 and has
        -- no length setting, so it is taken out in favor of the bar drawn in
        -- InfoBar.lua. (Walk backwards: entries are removed while iterating.)
        if bar.showXP then
            for i = #cfg.blocks, 1, -1 do
                local block = cfg.blocks[i]
                if type(block) == "table" and block.type == "xprep" then table.remove(cfg.blocks, i) end
            end
        end
    end
    return true
end

I.AddStep({
    order = 40,
    option = "dataBar",
    run = function(ctx)
        local bar = ctx.db.bar
        bar.xpLong = false
        if not bar.enabled then
            ctx:Skip("menu bar (switched off)")
            return
        end
        if Write(ctx) then
            ctx.menuBar = true
            bar.xpLong = bar.showXP and true or false
            ctx:Done("menu bar")
        else
            ctx:Skip("menu bar (EllesmereUI DataBars is not loaded)")
        end
    end,
})
