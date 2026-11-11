local addonName, ns = ...

-------------------------------------------------------------------------------
--  Menu bar backdrop
--  The menu bar itself is EllesmereUI's DataBar (the installer sets it up).
--  This file adds the two things that bar cannot do:
--
--   - a backdrop that fades: solid at the screen edge, clear toward the middle
--     of the screen, with a soft class-color wash at both ends
--   - a longer experience bar, in the gap the installer leaves after the menu
--     icons (EllesmereUI's own XP block is as long as its label and no longer)
--
--  It takes no mouse input, opens no Blizzard panel and is not a protected
--  frame, so it is safe to build and update at any time. Everything is event
--  driven.
-------------------------------------------------------------------------------

local bar
local floor = math.floor

-- EllesmereUI's DataBar is 30 high.
local BAR_HEIGHT = 30
function ns.InfoBarHeight() return BAR_HEIGHT end

-- "12% to level 5". Experience and level are not health, power or names, but
-- they are still checked for secrecy before any maths.
local function XPLabel(cur, max)
    if type(cur) ~= "number" or type(max) ~= "number" or ns.IsSecret(cur) or ns.IsSecret(max) then return "" end
    if max <= 0 then return "" end
    local percent = floor(cur / max * 100)
    local level = UnitLevel and UnitLevel("player")
    if type(level) == "number" and not ns.IsSecret(level) then return string.format(ns.L["%d%% to level %d"], percent, level + 1) end
    return percent .. "%"
end

local function UpdateXP()
    if not bar then return end
    local cfg = ns.db.bar
    local show = cfg.enabled and cfg.showXP and cfg.xpLong and UnitXP and UnitXPMax
    if show then
        local cur, max = UnitXP("player"), UnitXPMax("player")
        -- Straight into the status bar: no comparison, no arithmetic.
        bar.xp:SetMinMaxValues(0, max)
        bar.xp:SetValue(cur)
        bar.xpText:SetText(XPLabel(cur, max))
    end
    bar.xp:SetShown(show and true or false)
end

local function ApplyColors()
    if not bar then return end
    local lr, lg, lb, rr, rg, rb = ns.ClassGradient()

    bar.xp:SetStatusBarColor(1, 1, 1, 1)
    local fill = bar.xp:GetStatusBarTexture()
    if fill then ns.HGradient(fill, lr, lg, lb, 1, rr, rg, rb, 1) end

    -- The wash texture fades sideways; the vertex gradient fades it upward
    -- too, so it melts into the backdrop instead of ending in an edge.
    local cr, cg, cb = ns.GetPlayerClassColor()
    if CreateColor then
        local solid, clear = CreateColor(cr, cg, cb, 0.30), CreateColor(cr, cg, cb, 0)
        local low, high = solid, clear
        if bar.isTop then
            low, high = clear, solid
        end
        bar.washLeft:SetGradient("VERTICAL", low, high)
        bar.washRight:SetGradient("VERTICAL", low, high)
    else
        bar.washLeft:SetVertexColor(cr, cg, cb, 0.2)
        bar.washRight:SetVertexColor(cr, cg, cb, 0.2)
    end
end

-- Re-run whenever a setting changes.
function ns.ApplyInfoBar()
    if not bar or not ns.db then return end
    local cfg = ns.db.bar

    if not cfg.enabled then
        bar:Hide()
        return
    end

    local top = (cfg.position == "TOP")
    local outer = top and "TOP" or "BOTTOM"
    bar.isTop = top

    bar:ClearAllPoints()
    bar:SetPoint(outer .. "LEFT", UIParent, outer .. "LEFT", 0, 0)
    bar:SetPoint(outer .. "RIGHT", UIParent, outer .. "RIGHT", 0, 0)
    bar:SetHeight(BAR_HEIGHT)

    -- Backdrop: solid at the screen edge, fading to nothing a little past the
    -- bar's inner edge so the fade has room to be soft.
    local opacity = cfg.opacity
    if type(opacity) ~= "number" then opacity = 80 end
    if opacity < 0 then
        opacity = 0
    elseif opacity > 100 then
        opacity = 100
    end
    local reach = floor(BAR_HEIGHT * 0.55 + 0.5)
    bar.bg:ClearAllPoints()
    bar.bg:SetPoint(outer .. "LEFT", bar, outer .. "LEFT", 0, 0)
    bar.bg:SetPoint(outer .. "RIGHT", bar, outer .. "RIGHT", 0, 0)
    bar.bg:SetHeight(BAR_HEIGHT + reach)
    if CreateColor then
        local solid = CreateColor(0.035, 0.04, 0.05, opacity / 100)
        local clear = CreateColor(0.035, 0.04, 0.05, 0)
        if top then
            bar.bg:SetGradient("VERTICAL", clear, solid)
        else
            bar.bg:SetGradient("VERTICAL", solid, clear)
        end
    else
        bar.bg:SetVertexColor(0.035, 0.04, 0.05, opacity / 100)
    end

    -- Class wash: same height as the backdrop, from each end to near the middle.
    bar.washLeft:ClearAllPoints()
    bar.washLeft:SetPoint(outer .. "LEFT", bar, outer .. "LEFT", 0, 0)
    bar.washLeft:SetPoint("RIGHT", bar, "CENTER", -120, 0)
    bar.washLeft:SetHeight(BAR_HEIGHT + reach)
    bar.washRight:ClearAllPoints()
    bar.washRight:SetPoint(outer .. "RIGHT", bar, outer .. "RIGHT", 0, 0)
    bar.washRight:SetPoint("LEFT", bar, "CENTER", 120, 0)
    bar.washRight:SetHeight(BAR_HEIGHT + reach)
    bar.washLeft:SetShown(cfg.classWash)
    bar.washRight:SetShown(cfg.classWash)

    -- Long XP bar: a thin line with its label on the side facing the screen.
    local length = cfg.xpLength
    if type(length) ~= "number" then length = 320 end
    if length < 60 then
        length = 60
    elseif length > 1200 then
        length = 1200
    end
    local offset = cfg.xpOffset
    if type(offset) ~= "number" then offset = 320 end
    bar.xp:ClearAllPoints()
    bar.xp:SetPoint(outer .. "LEFT", bar, outer .. "LEFT", offset, top and -7 or 7)
    bar.xp:SetSize(length, 3)
    ns.SetFont(bar.xpText, 11)
    bar.xpText:ClearAllPoints()
    if top then
        bar.xpText:SetPoint("TOPLEFT", bar.xp, "BOTTOMLEFT", 0, -2)
    else
        bar.xpText:SetPoint("BOTTOMLEFT", bar.xp, "TOPLEFT", 0, 2)
    end

    bar:Show()
    ApplyColors()
    UpdateXP()
end

local function Build()
    bar = CreateFrame("Frame", "AritlokUIInfoBar", UIParent)
    bar:SetFrameStrata("BACKGROUND") -- behind EllesmereUI's DataBar
    bar:EnableMouse(false)

    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetColorTexture(1, 1, 1, 1)

    -- Class-color wash fading in from each end toward the middle.
    bar.washLeft = bar:CreateTexture(nil, "BORDER")
    bar.washLeft:SetTexture(ns.media.fade)
    bar.washLeft:SetTexCoord(1, 0, 0, 1)

    bar.washRight = bar:CreateTexture(nil, "BORDER")
    bar.washRight:SetTexture(ns.media.fade)

    bar.xp = CreateFrame("StatusBar", nil, bar)
    bar.xp:SetStatusBarTexture(ns.media.white)
    bar.xp:SetFrameLevel(bar:GetFrameLevel() + 1)
    local track = bar.xp:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    track:SetColorTexture(1, 1, 1, 0.1)

    bar.xpText = bar.xp:CreateFontString(nil, "OVERLAY")
    bar.xpText:SetJustifyH("LEFT")
    bar.xpText:SetTextColor(1, 1, 1)
    ns.SetFont(bar.xpText, 11) -- a font must be set before any SetText
    bar.xp:Hide()
end

ns.On("PLAYER_LOGIN", function()
    Build()
    ns.ApplyInfoBar()

    -- Follow EllesmereUI's accent color live when it offers the callback.
    local eui = _G.EllesmereUI
    if type(eui) == "table" and eui.RegAccent then eui.RegAccent({ type = "callback", fn = function() ApplyColors() end }) end
end)

ns.On("PLAYER_ENTERING_WORLD", function()
    if not bar then return end
    ApplyColors()
    UpdateXP()
end)

ns.On("PLAYER_XP_UPDATE", UpdateXP)
ns.On("PLAYER_LEVEL_UP", UpdateXP)
