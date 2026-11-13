local addonName, ns = ...

-------------------------------------------------------------------------------
--  Menu bar backdrop
--  The menu bar itself is EllesmereUI's DataBar (the installer sets it up).
--  This file adds the two things that bar cannot do:
--
--   - a backdrop that fades: solid at the screen edge, clear toward the middle
--     of the screen, with a soft class-color wash at both ends
--   - a longer experience bar, in the gap the installer leaves after the menu
--     icons (EllesmereUI's own XP block is as long as its label and no longer),
--     with rested experience as a lighter section past the fill and a
--     tooltip; at max level it shows the watched faction's reputation instead
--
--  Only the bar's small hover area takes the mouse (no clicks). Nothing here
--  opens a Blizzard panel or is a protected frame, so it is safe to build and
--  update at any time. Everything is event driven.
-------------------------------------------------------------------------------

local bar
local floor = math.floor

-- EllesmereUI's DataBar is 30 high.
local BAR_HEIGHT = 30
function ns.InfoBarHeight() return BAR_HEIGHT end

local L = ns.L

-- A number from the client, or nil when it is missing or secret. Experience,
-- rested experience and reputation are not health, power or names, but they
-- are still checked before any maths.
local function Num(v)
    if type(v) == "number" and not ns.IsSecret(v) then return v end
    return nil
end

local function Big(n)
    if BreakUpLargeNumbers then return BreakUpLargeNumbers(n) end
    return tostring(n)
end

-- The same max-level checks as EllesmereUI's own XP block (DataBars,
-- Blocks/Shared.lua K.AtMaxLevel), which runs on Forever.
local function AtMaxLevel()
    if IsPlayerAtEffectiveMaxLevel then
        local atMax = IsPlayerAtEffectiveMaxLevel()
        if atMax == true then return true end
    end
    local level = Num(UnitLevel and UnitLevel("player"))
    if not level then return false end
    if IsLevelAtEffectiveMaxLevel and IsLevelAtEffectiveMaxLevel(level) == true then return true end
    local maxLevel = Num((GetMaxLevelForPlayerExpansion and GetMaxLevelForPlayerExpansion()) or (GetMaxPlayerLevel and GetMaxPlayerLevel()))
    return maxLevel ~= nil and level >= maxLevel
end

-- The watched faction: name, reaction (1-8), and the standing's low and high
-- ends and the current value. Both client APIs, as EllesmereUI's XP block
-- reads them.
local function WatchedFaction()
    local legacy = rawget(_G, "GetWatchedFactionInfo")
    if legacy then
        local name, reaction, low, high, value = legacy()
        return name, reaction, low, high, value
    end
    local rep = _G.C_Reputation
    if rep and rep.GetWatchedFactionData then
        local d = rep.GetWatchedFactionData()
        if type(d) == "table" then return d.name, d.reaction, d.currentReactionThreshold, d.nextReactionThreshold, d.currentStanding end
    end
    return nil
end

local function StandingName(reaction)
    local name = reaction and _G["FACTION_STANDING_LABEL" .. tostring(reaction)]
    return type(name) == "string" and name or ""
end

-- What the bar shows: "xp", "rep" or nil (nothing to show).
local mode, repReaction

-- The current numbers for the label, the tooltip and the rested section.
local state = {}

local function ReadState()
    local cfg = ns.db.bar
    for k in pairs(state) do
        state[k] = nil
    end
    local xpOff = IsXPUserDisabled and IsXPUserDisabled() == true
    if not AtMaxLevel() and not xpOff then
        local cur, max = Num(UnitXP and UnitXP("player")), Num(UnitXPMax and UnitXPMax("player"))
        if not (cur and max and max > 0) then return nil end
        state.cur, state.max = cur, max
        state.level = Num(UnitLevel("player"))
        state.rested = Num(GetXPExhaustion and GetXPExhaustion()) or 0
        state.resting = IsResting and IsResting() == true
        return "xp"
    end
    if not cfg.repAtMax then return nil end
    local name, reaction, low, high, value = WatchedFaction()
    low, high, value = Num(low), Num(high), Num(value)
    if type(name) ~= "string" or ns.IsSecret(name) or not (low and high and value) or high <= low then return nil end
    state.name, state.reaction = name, Num(reaction)
    state.cur, state.max = value - low, high - low
    return "rep"
end

local function Label()
    local percent = math.floor(state.cur / state.max * 100)
    if mode == "rep" then return string.format(L["%s: %s %d%%"], state.name, StandingName(state.reaction), percent) end
    local text
    if state.level then
        text = string.format(L["%d%% to level %d"], percent, state.level + 1)
    else
        text = percent .. "%"
    end
    if ns.db.bar.showRested and state.rested > 0 then
        text = text .. "  " .. string.format(L["%d%% rested"], math.floor(state.rested / state.max * 100))
    end
    return text
end

-- Rested experience: a lighter section from the end of the fill to where the
-- rested bonus runs out (at most the end of the level).
local function UpdateRested()
    local cfg = ns.db.bar
    local fill = bar.xp:GetStatusBarTexture()
    local width = bar.xp:GetWidth()
    if mode ~= "xp" or not cfg.showRested or state.rested <= 0 or not fill or not width or width <= 0 then
        bar.rested:Hide()
        return
    end
    local reach = math.min(state.rested, state.max - state.cur)
    if reach <= 0 then
        bar.rested:Hide()
        return
    end
    bar.rested:ClearAllPoints()
    bar.rested:SetPoint("TOPLEFT", fill, "TOPRIGHT")
    bar.rested:SetPoint("BOTTOMLEFT", fill, "BOTTOMRIGHT")
    bar.rested:SetWidth(math.max(1, width * reach / state.max))
    bar.rested:Show()
end

local ApplyColors

local function UpdateXP()
    if not bar then return end
    local cfg = ns.db.bar
    mode = nil
    if cfg.enabled and cfg.showXP and cfg.xpLong then mode = ReadState() end
    if mode then
        -- The values are plain numbers here (Num above), checked before use.
        bar.xp:SetMinMaxValues(0, state.max)
        bar.xp:SetValue(state.cur)
        bar.xpText:SetText(Label())
    end
    bar.xp:SetShown(mode ~= nil)
    bar.hover:SetShown(mode ~= nil)
    if mode == "rep" and state.reaction ~= repReaction then
        repReaction = state.reaction
        ApplyColors()
    elseif mode ~= "rep" and repReaction then
        repReaction = nil
        ApplyColors()
    end
    if mode then UpdateRested() end
end

-- The tooltip on the bar.
local function ShowTooltip(owner)
    if not mode then return end
    local top = bar.isTop
    GameTooltip:SetOwner(owner, top and "ANCHOR_BOTTOM" or "ANCHOR_TOP")
    local percent = math.floor(state.cur / state.max * 100)
    if mode == "rep" then
        GameTooltip:AddLine(state.name, 1, 1, 1)
        GameTooltip:AddDoubleLine(L["Standing"], StandingName(state.reaction), 0.7, 0.7, 0.75, 1, 1, 1)
        GameTooltip:AddDoubleLine(
            L["Progress"],
            string.format("%s / %s (%d%%)", Big(state.cur), Big(state.max), percent),
            0.7,
            0.7,
            0.75,
            1,
            1,
            1
        )
    else
        if state.level then GameTooltip:AddLine(string.format(L["Level %d"], state.level), 1, 1, 1) end
        GameTooltip:AddDoubleLine(
            L["Experience"],
            string.format("%s / %s (%d%%)", Big(state.cur), Big(state.max), percent),
            0.7,
            0.7,
            0.75,
            1,
            1,
            1
        )
        GameTooltip:AddDoubleLine(L["To next level"], Big(state.max - state.cur), 0.7, 0.7, 0.75, 1, 1, 1)
        if state.rested > 0 then
            local restedPercent = math.floor(state.rested / state.max * 100)
            GameTooltip:AddDoubleLine(
                L["Rested"],
                string.format("%s (%d%%)", Big(state.rested), restedPercent),
                0.7,
                0.7,
                0.75,
                0.55,
                0.75,
                1
            )
        else
            GameTooltip:AddDoubleLine(L["Rested"], L["none"], 0.7, 0.7, 0.75, 0.6, 0.6, 0.65)
        end
        if state.resting then GameTooltip:AddLine(L["Resting: rested experience builds up."], 0.55, 0.75, 1, true) end
    end
    GameTooltip:Show()
end

function ApplyColors()
    if not bar then return end
    local lr, lg, lb, rr, rg, rb = ns.ClassGradient()
    -- Rested section: the light end of the class gradient, see-through.
    bar.rested:SetColorTexture(rr, rg, rb, 0.35)
    -- Reputation: the standing's own color instead of the class color.
    local standing = repReaction and _G.FACTION_BAR_COLORS and _G.FACTION_BAR_COLORS[repReaction]
    if standing then
        lr, lg, lb, rr, rg, rb = ns.GradientPair(standing.r, standing.g, standing.b)
    end

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

    bar.hover:ClearAllPoints()
    if top then
        bar.hover:SetPoint("TOPLEFT", bar.xp, "TOPLEFT", 0, 4)
        bar.hover:SetPoint("BOTTOMRIGHT", bar.xp, "BOTTOMRIGHT", 0, -18)
    else
        bar.hover:SetPoint("TOPLEFT", bar.xp, "TOPLEFT", 0, 18)
        bar.hover:SetPoint("BOTTOMRIGHT", bar.xp, "BOTTOMRIGHT", 0, -4)
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

    -- Behind the fill, so it only shows past the fill's end.
    bar.rested = bar.xp:CreateTexture(nil, "BORDER")
    bar.rested:Hide()

    bar.xpText = bar.xp:CreateFontString(nil, "OVERLAY")
    bar.xpText:SetJustifyH("LEFT")
    bar.xpText:SetTextColor(1, 1, 1)
    ns.SetFont(bar.xpText, 11) -- a font must be set before any SetText
    bar.xp:Hide()

    -- Hover area over the bar and its label, for the tooltip. Above the
    -- DataBar (which sits at MEDIUM), but only over the room the installer
    -- leaves free for this bar. It takes mouse-over only; clicks pass through.
    bar.hover = CreateFrame("Frame", nil, UIParent)
    bar.hover:SetFrameStrata("HIGH")
    if bar.hover.SetMouseMotionEnabled and bar.hover.SetMouseClickEnabled then
        bar.hover:SetMouseMotionEnabled(true)
        bar.hover:SetMouseClickEnabled(false)
    else
        bar.hover:EnableMouse(true)
    end
    bar.hover:SetScript("OnEnter", ShowTooltip)
    bar.hover:SetScript("OnLeave", function() GameTooltip:Hide() end)
    bar.hover:Hide()
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
ns.On("UPDATE_EXHAUSTION", UpdateXP) -- rested experience changed
ns.On("PLAYER_UPDATE_RESTING", UpdateXP)
ns.On("UPDATE_FACTION", UpdateXP) -- reputation, and the watched faction
ns.On("ENABLE_XP_GAIN", UpdateXP) -- rejected harmlessly where the client has no such event
ns.On("DISABLE_XP_GAIN", UpdateXP)
