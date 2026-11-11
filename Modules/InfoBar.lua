local addonName, ns = ...

-------------------------------------------------------------------------------
--  Info bar
--  A slim strip along the bottom (or top) of the screen. Two modes:
--
--  "own"  This addon draws everything:
--
--   [menu buttons]  DUR 100%   VOL 20%        11/11/2026        gold (bags)   FPS  MS   ZONE
--                                               19:42
--
--  "eui"  EllesmereUI's DataBars module draws the bar (icon micro menu, clock,
--         gold and so on; the installer sets it up) and this file only paints
--         the fading backdrop behind it.
--
--  The menu buttons of the "own" mode live in MicroBar.lua. The background is
--  a vertical fade: solid at the screen edge, clear toward the middle of the
--  screen.
--
--  The bar itself informs only: it takes no mouse input, opens no Blizzard
--  panel and is not a protected frame, so it is safe to build and update at
--  any time. Everything is event driven except the clock and the fps/latency
--  readout, which have no event and share one 1-second ticker.
-------------------------------------------------------------------------------

local bar
local state = { fps = "", ms = "", bags = "", dura = "", gold = "", volume = "" }
local accentHex = "18a8ff"
local textFrom = { 0.094, 0.659, 1.0 } -- gradient ends for the bar's own text
local textTo = { 1, 1, 1 }
local ticker

local floor = math.floor

-------------------------------------------------------------------------------
--  Readers. Each returns display text; none of them touches unit health,
--  power or names. Client values are still checked for secrecy before maths.
-------------------------------------------------------------------------------
local function ReadGold()
    if not GetMoney then return "" end
    local money = GetMoney()
    if type(money) ~= "number" or ns.IsSecret(money) then return "" end
    local gold = floor(money / 10000)
    local silver = floor((money % 10000) / 100)
    local copper = money % 100
    local goldText = BreakUpLargeNumbers and BreakUpLargeNumbers(gold) or tostring(gold)
    return string.format("%s|cffffd100g|r %d|cffc7c7cfs|r %d|cffeda55fc|r", goldText, silver, copper)
end

local function ReadBags()
    local getFree = C_Container and C_Container.GetContainerNumFreeSlots
    if not getFree then return "" end
    local free = 0
    local last = NUM_BAG_SLOTS or 4
    for bag = 0, last do
        local n = getFree(bag)
        if type(n) == "number" and not ns.IsSecret(n) then free = free + n end
    end
    return tostring(free)
end

local function ReadDurability()
    if not GetInventoryItemDurability then return "" end
    local lowest
    for slot = 1, 18 do
        local cur, max = GetInventoryItemDurability(slot)
        if type(cur) == "number" and type(max) == "number" and not ns.IsSecret(cur) and not ns.IsSecret(max) and max > 0 then
            local pct = cur / max
            if not lowest or pct < lowest then lowest = pct end
        end
    end
    if not lowest then return "" end
    local pct = floor(lowest * 100 + 0.5)
    local color = (pct <= 25 and "ff4040") or (pct <= 50 and "ffb040") or "ffffff"
    return string.format("|cff%s%d%%|r", color, pct)
end

local function ReadVolume()
    if not GetCVar then return "" end
    local raw = GetCVar("Sound_MasterVolume")
    if raw == nil or ns.IsSecret(raw) then return "" end
    local v = tonumber(raw)
    if not v then return "" end
    return string.format("%d%%", floor(v * 100 + 0.5))
end

local function ReadPerformance()
    local fps, ms = "", ""
    if GetFramerate then
        local f = GetFramerate()
        if type(f) == "number" and not ns.IsSecret(f) then fps = tostring(floor(f + 0.5)) end
    end
    if GetNetStats then
        local _, _, home, world = GetNetStats()
        local latency = world
        if type(latency) ~= "number" or ns.IsSecret(latency) or latency == 0 then latency = home end
        if type(latency) == "number" and not ns.IsSecret(latency) then ms = tostring(floor(latency + 0.5)) end
    end
    return fps, ms
end

local function ReadClock()
    local cfg = ns.db.bar
    if cfg.localTime or not GetGameTime then return date(cfg.clock24 and "%H:%M" or "%I:%M %p") end
    local hour, minute = GetGameTime()
    if type(hour) ~= "number" or type(minute) ~= "number" then return "" end
    if cfg.clock24 then return string.format("%02d:%02d", hour, minute) end
    local suffix = hour >= 12 and "PM" or "AM"
    local h12 = hour % 12
    if h12 == 0 then h12 = 12 end
    return string.format("%d:%02d %s", h12, minute, suffix)
end

-------------------------------------------------------------------------------
--  Painting
-------------------------------------------------------------------------------
local function Segment(label, value)
    if value == "" then return nil end
    return string.format("|cff%s%s|r %s", accentHex, label, value)
end

local function PaintStats()
    if not bar or not bar.own then return end

    local left = {}
    left[#left + 1] = Segment("DUR", state.dura)
    left[#left + 1] = Segment("VOL", state.volume)
    bar.left:SetText(table.concat(left, "      "))

    local right = {}
    if state.gold ~= "" then
        local gold = state.gold
        if state.bags ~= "" then gold = gold .. string.format("  |cff%s(%s)|r", accentHex, state.bags) end
        right[#right + 1] = gold
    end
    right[#right + 1] = Segment("FPS", state.fps)
    right[#right + 1] = Segment("MS", state.ms)
    bar.right:SetText(table.concat(right, "      "))
end

local function UpdateZone()
    if not bar or not bar.own then return end
    local zone = GetMinimapZoneText and GetMinimapZoneText()
    if zone == nil then
        bar.zone:SetText("")
    elseif ns.IsSecret(zone) then
        -- A FontString accepts a secret string; it is only handed to SetText.
        bar.zone:SetText(zone)
    else
        bar.zone:SetText(ns.GradientText(string.upper(zone), textTo[1], textTo[2], textTo[3], 1, 1, 1))
    end
end

local function UpdateMail()
    if not bar or not bar.own then return end
    local has = HasNewMail and HasNewMail()
    if ns.IsSecret(has) then has = false end
    bar.mail:SetShown(has and true or false)
end

-- "12% to level 5" for the long XP bar. Experience and level are not health,
-- power or names, but they are still checked for secrecy before any maths.
local function XPLabel(cur, max)
    if type(cur) ~= "number" or type(max) ~= "number" or ns.IsSecret(cur) or ns.IsSecret(max) then return "" end
    if max <= 0 then return "" end
    local text = floor(cur / max * 100) .. "%"
    local level = UnitLevel and UnitLevel("player")
    if type(level) == "number" and not ns.IsSecret(level) then text = text .. " to level " .. (level + 1) end
    return text
end

local function UpdateXP()
    if not bar then return end
    local cfg = ns.db.bar
    local have = cfg.showXP and UnitXP and UnitXPMax
    local hairline = have and bar.own
    local long = have and not bar.own and cfg.xpLong

    if hairline or long then
        local cur, max = UnitXP("player"), UnitXPMax("player")
        local target = hairline and bar.xp or bar.xpLong
        -- Straight into the status bar: no comparison, no arithmetic.
        target:SetMinMaxValues(0, max)
        target:SetValue(cur)
        if long then bar.xpText:SetText(XPLabel(cur, max)) end
    end
    bar.xp:SetShown(hairline and true or false)
    bar.xpLong:SetShown(long and true or false)
end

local function UpdateGold()
    state.gold = ReadGold()
    PaintStats()
end
local function UpdateBags()
    state.bags = ReadBags()
    PaintStats()
end
local function UpdateDurability()
    state.dura = ReadDurability()
    PaintStats()
end
local function UpdateVolume()
    state.volume = ReadVolume()
    PaintStats()
end

local function Tick()
    if not bar or not bar.own or not bar:IsShown() then return end
    bar.clock:SetText(ns.GradientText(ReadClock(), textFrom[1], textFrom[2], textFrom[3], textTo[1], textTo[2], textTo[3]))
    bar.date:SetText(date("%d/%m/%Y"))
    local fps, ms = ReadPerformance()
    if fps ~= state.fps or ms ~= state.ms then
        state.fps, state.ms = fps, ms
        PaintStats()
    end
end

local function ApplyColors()
    if not bar then return end
    local ar, ag, ab = ns.GetAccent()
    accentHex = ns.Hex(ar, ag, ab)
    bar.clock:SetTextColor(1, 1, 1)
    bar.date:SetTextColor(ar, ag, ab)
    bar.mail:SetVertexColor(ar, ag, ab, 1)

    -- Text and the XP line run from the class gradient's deep end to its
    -- light end.
    local lr, lg, lb, rr, rg, rb = ns.ClassGradient()
    textFrom[1], textFrom[2], textFrom[3] = lr + (rr - lr) * 0.5, lg + (rg - lg) * 0.5, lb + (rb - lb) * 0.5
    textTo[1], textTo[2], textTo[3] = rr, rg, rb
    bar.xp:SetStatusBarColor(1, 1, 1, 1)
    local xpFill = bar.xp:GetStatusBarTexture()
    if xpFill then ns.HGradient(xpFill, lr, lg, lb, 1, rr, rg, rb, 1) end
    bar.xpLong:SetStatusBarColor(1, 1, 1, 1)
    local longFill = bar.xpLong:GetStatusBarTexture()
    if longFill then ns.HGradient(longFill, lr, lg, lb, 1, rr, rg, rb, 1) end

    -- The wash texture fades sideways; the vertex gradient fades it upward
    -- too, so it melts into the background fade instead of ending in an edge.
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

    UpdateZone()
    PaintStats()
end

-------------------------------------------------------------------------------
--  Layout (re-run whenever a setting changes)
-------------------------------------------------------------------------------
-- Height of the strip at the screen edge, in either mode. EllesmereUI's
-- DataBar is 30 high.
function ns.InfoBarHeight()
    local cfg = ns.db and ns.db.bar
    if cfg and cfg.mode == "eui" then return 30 end
    local height = cfg and cfg.height
    if type(height) ~= "number" then height = 28 end
    if height < 18 then
        height = 18
    elseif height > 48 then
        height = 48
    end
    return height
end

function ns.ApplyInfoBar()
    if not bar or not ns.db then return end
    local cfg = ns.db.bar
    local own = (cfg.mode ~= "eui")
    bar.own = own

    -- The menu buttons are protected frames; MicroBar.lua queues itself when
    -- in combat.
    if ns.ApplyMicroBar then ns.ApplyMicroBar() end

    if not cfg.enabled then
        bar:Hide()
        return
    end

    local height = ns.InfoBarHeight()
    local top = (cfg.position == "TOP")

    bar:ClearAllPoints()
    if top then
        bar:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
        bar:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)
    else
        bar:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
        bar:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
    end
    bar:SetHeight(height)
    bar.isTop = top
    -- Behind EllesmereUI's DataBar when it draws the content.
    bar:SetFrameStrata(own and "LOW" or "BACKGROUND")

    -- Background: solid at the screen edge, fading to nothing past the bar's
    -- inner edge. It reaches beyond the bar so the fade has room to be soft.
    local opacity = cfg.opacity
    if type(opacity) ~= "number" then opacity = 80 end
    if opacity < 0 then
        opacity = 0
    elseif opacity > 100 then
        opacity = 100
    end
    local outer = top and "TOP" or "BOTTOM"
    local reach = floor(height * 0.55 + 0.5)
    bar.bg:ClearAllPoints()
    bar.bg:SetPoint(outer .. "LEFT", bar, outer .. "LEFT", 0, 0)
    bar.bg:SetPoint(outer .. "RIGHT", bar, outer .. "RIGHT", 0, 0)
    bar.bg:SetHeight(height + reach)
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

    -- Class wash: same height as the background, from each end to near the middle.
    bar.washLeft:ClearAllPoints()
    bar.washLeft:SetPoint(outer .. "LEFT", bar, outer .. "LEFT", 0, 0)
    bar.washLeft:SetPoint("RIGHT", bar, "CENTER", -120, 0)
    bar.washLeft:SetHeight(height + reach)
    bar.washRight:ClearAllPoints()
    bar.washRight:SetPoint(outer .. "RIGHT", bar, outer .. "RIGHT", 0, 0)
    bar.washRight:SetPoint("LEFT", bar, "CENTER", 120, 0)
    bar.washRight:SetHeight(height + reach)
    bar.washLeft:SetShown(cfg.classWash)
    bar.washRight:SetShown(cfg.classWash)

    bar.text:SetShown(own)
    bar:Show()

    if not own then
        -- EllesmereUI's DataBar draws the content. Its XP block cannot be made
        -- longer (the bar is as long as its label plus 40), so the installer
        -- removes that block and leaves a gap after the menu icons; this bar
        -- fills the gap at whatever length is set.
        local length = cfg.xpLength
        if type(length) ~= "number" then length = 320 end
        if length < 60 then
            length = 60
        elseif length > 1200 then
            length = 1200
        end
        local offset = cfg.xpOffset
        if type(offset) ~= "number" then offset = 320 end
        bar.xpLong:ClearAllPoints()
        bar.xpLong:SetPoint(outer .. "LEFT", bar, outer .. "LEFT", offset, top and -7 or 7)
        bar.xpLong:SetSize(length, 3)
        ns.SetFont(bar.xpText, 11)
        bar.xpText:ClearAllPoints()
        if top then
            bar.xpText:SetPoint("TOPLEFT", bar.xpLong, "BOTTOMLEFT", 0, -2)
        else
            bar.xpText:SetPoint("BOTTOMLEFT", bar.xpLong, "TOPLEFT", 0, 2)
        end
        ApplyColors()
        UpdateXP()
        return
    end

    -- XP hairline on the screen edge, under the solid end of the fade.
    bar.xp:ClearAllPoints()
    bar.xp:SetPoint(outer .. "LEFT", bar, outer .. "LEFT", 0, 0)
    bar.xp:SetPoint(outer .. "RIGHT", bar, outer .. "RIGHT", 0, 0)
    bar.xp:SetHeight(2)

    local small = floor(height * 0.42 + 0.5)
    if small < 10 then small = 10 end
    ns.SetFont(bar.left, small)
    ns.SetFont(bar.right, small)
    ns.SetFont(bar.zone, small)
    ns.SetFont(bar.date, small)
    ns.SetFont(bar.clock, floor(height * 0.8 + 0.5))

    -- Left text starts after the menu buttons.
    local leftPad = 16 + ((ns.MicroBarWidth and ns.MicroBarWidth()) or 0)
    bar.left:ClearAllPoints()
    bar.left:SetPoint("LEFT", bar, "LEFT", leftPad, 0)

    -- Clock on the screen edge, date stacked on the side facing the screen.
    bar.clock:ClearAllPoints()
    bar.date:ClearAllPoints()
    if top then
        bar.clock:SetPoint("TOP", bar, "TOP", 0, -3)
        bar.date:SetPoint("TOP", bar.clock, "BOTTOM", 0, -1)
    else
        bar.clock:SetPoint("BOTTOM", bar, "BOTTOM", 0, 4)
        bar.date:SetPoint("BOTTOM", bar.clock, "TOP", 0, 1)
    end

    ApplyColors()
    UpdateMail()
    UpdateXP()
    state.gold = ReadGold()
    state.bags = ReadBags()
    state.dura = ReadDurability()
    state.volume = ReadVolume()
    Tick()
    PaintStats()
end

local function Build()
    bar = CreateFrame("Frame", "AritlokUIInfoBar", UIParent)
    bar:SetFrameStrata("LOW")
    bar:EnableMouse(false)
    bar.own = true

    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetColorTexture(1, 1, 1, 1)

    -- Class-colour wash fading in from each end toward the middle.
    bar.washLeft = bar:CreateTexture(nil, "BORDER")
    bar.washLeft:SetTexture(ns.media.fade)
    bar.washLeft:SetTexCoord(1, 0, 0, 1)

    bar.washRight = bar:CreateTexture(nil, "BORDER")
    bar.washRight:SetTexture(ns.media.fade)

    bar.xp = CreateFrame("StatusBar", nil, bar)
    bar.xp:SetStatusBarTexture(ns.media.white)
    bar.xp:SetFrameLevel(bar:GetFrameLevel() + 1)

    -- Long XP bar for the EllesmereUI DataBar mode: thin bar, label above it.
    bar.xpLong = CreateFrame("StatusBar", nil, bar)
    bar.xpLong:SetStatusBarTexture(ns.media.white)
    bar.xpLong:SetFrameLevel(bar:GetFrameLevel() + 1)
    local track = bar.xpLong:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    track:SetColorTexture(1, 1, 1, 0.1)
    bar.xpText = bar.xpLong:CreateFontString(nil, "OVERLAY")
    bar.xpText:SetJustifyH("LEFT")
    bar.xpText:SetTextColor(1, 1, 1)
    ns.SetFont(bar.xpText, 11)
    bar.xpLong:Hide()

    local text = CreateFrame("Frame", nil, bar)
    text:SetAllPoints()
    text:SetFrameLevel(bar:GetFrameLevel() + 2)
    bar.text = text

    local function Text(justify)
        local fs = text:CreateFontString(nil, "OVERLAY")
        fs:SetJustifyH(justify)
        fs:SetTextColor(1, 1, 1)
        ns.SetFont(fs, 12) -- a font must be set before any SetText
        return fs
    end

    bar.left = Text("LEFT")

    bar.zone = Text("RIGHT")
    bar.zone:SetPoint("RIGHT", bar, "RIGHT", -16, 0)

    bar.right = Text("RIGHT")
    bar.right:SetPoint("RIGHT", bar.zone, "LEFT", -24, 0)

    bar.mail = text:CreateTexture(nil, "OVERLAY")
    bar.mail:SetTexture(ns.media.dot)
    bar.mail:SetSize(10, 10)
    bar.mail:SetPoint("LEFT", bar.left, "RIGHT", 12, 0)
    bar.mail:Hide()

    bar.clock = Text("CENTER")
    bar.date = Text("CENTER")
end

-------------------------------------------------------------------------------
--  Events
-------------------------------------------------------------------------------
ns.On("PLAYER_LOGIN", function()
    Build()
    ns.ApplyInfoBar()

    if C_Timer and C_Timer.NewTicker then ticker = C_Timer.NewTicker(1, Tick) end

    -- Follow EllesmereUI's accent colour live when it offers the callback.
    local eui = _G.EllesmereUI
    if type(eui) == "table" and eui.RegAccent then eui.RegAccent({ type = "callback", fn = function() ApplyColors() end }) end
end)

ns.On("PLAYER_ENTERING_WORLD", function()
    if not bar then return end
    ApplyColors()
    UpdateMail()
    UpdateXP()
    UpdateGold()
    UpdateBags()
    UpdateDurability()
    UpdateVolume()
end)

ns.On("ZONE_CHANGED", UpdateZone)
ns.On("ZONE_CHANGED_INDOORS", UpdateZone)
ns.On("ZONE_CHANGED_NEW_AREA", UpdateZone)
ns.On("UPDATE_PENDING_MAIL", UpdateMail)
ns.On("PLAYER_XP_UPDATE", UpdateXP)
ns.On("PLAYER_LEVEL_UP", UpdateXP)
ns.On("PLAYER_MONEY", UpdateGold)
ns.On("BAG_UPDATE_DELAYED", UpdateBags)
ns.On("UPDATE_INVENTORY_DURABILITY", UpdateDurability)
ns.On("CVAR_UPDATE", UpdateVolume)
