local addonName, ns = ...

-------------------------------------------------------------------------------
--  AFK screen. While the player is flagged AFK (and not in combat): the
--  interface fades out, the camera turns slowly, and a panel along the bottom
--  shows the character, the time away and the clock. It ends when the AFK
--  flag clears, when combat starts, or on a click.
--
--  Nothing protected is touched. The interface is hidden with UIParent's
--  alpha, which is allowed at any time, not with Hide(), which is not allowed
--  in combat. The screen itself sits on WorldFrame, so it stays visible while
--  UIParent is see-through. The camera turn uses MoveViewLeftStart/Stop, the
--  same calls a key binding makes.
--
--  RETEST on a new client build: UnitIsAFK, MoveViewLeftStart/Stop and the
--  PlayerModel frame type are listed in /aui probe.
-------------------------------------------------------------------------------

local L = ns.L

local SPIN_SPEED = 0.035 -- slow; MoveViewLeftStart takes a speed multiplier

local screen -- built on first use
local active = false
local startedAt = 0
local ticker

local function Enabled()
    local db = ns.db
    return type(db) == "table" and db.afk.enabled and true or false
end

local function CanSpin()
    local db = ns.db
    return type(db) == "table" and db.afk.spin and type(MoveViewLeftStart) == "function" and type(MoveViewLeftStop) == "function"
end

-- "1:05" or "1:02:05", from a whole number of seconds.
local function Duration(seconds)
    seconds = math.floor(seconds)
    local h, m, s = math.floor(seconds / 3600), math.floor(seconds / 60) % 60, seconds % 60
    if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
    return string.format("%d:%02d", m, s)
end

local function Clock()
    local db = ns.db
    if type(db) == "table" and db.bar.clock24 then return date("%H:%M") end
    return date("%I:%M %p")
end

local function Tick()
    if not screen then return end
    screen.away:SetText(Duration(GetTime() - startedAt))
    screen.clock:SetText(Clock())
end

-- The character lines. Unit data is checked for secrecy before any use; a
-- secret name is still handed straight to SetText, which takes it.
local function FillCharacter()
    local cr, cg, cb = ns.GetPlayerClassColor()
    local lr, lg, lb, rr, rg, rb = ns.GradientPair(cr, cg, cb)

    local name = UnitName("player")
    if ns.IsSecret(name) then
        screen.name:SetText(name)
        screen.name:SetTextColor(cr, cg, cb)
    else
        screen.name:SetText(ns.GradientText(name or "", rr, rg, rb, cr, cg, cb))
        screen.name:SetTextColor(1, 1, 1)
    end

    local level = UnitLevel("player")
    local className = UnitClass("player")
    if ns.IsSecret(level) or ns.IsSecret(className) then
        screen.info:SetText("")
    else
        screen.info:SetText(string.format(L["Level %s %s"], tostring(level or ""), className or ""))
    end

    local guild = GetGuildInfo and GetGuildInfo("player")
    if guild and not ns.IsSecret(guild) then
        screen.guild:SetText("<" .. guild .. ">")
    else
        screen.guild:SetText("")
    end

    ns.HGradient(screen.line, lr, lg, lb, 1, rr, rg, rb, 1)
    screen.away:SetTextColor(cr, cg, cb)

    if screen.model then
        screen.model:SetUnit("player")
        screen.model:SetFacing(-0.45)
        screen.model:SetCamDistanceScale(1.1)
    end
end

local function Build()
    screen = CreateFrame("Frame", "AritlokUIAFK", WorldFrame)
    screen:SetFrameStrata("FULLSCREEN_DIALOG")
    screen:SetAllPoints(WorldFrame)
    screen:EnableMouse(true)
    screen:Hide()
    -- A click ends the screen; the AFK flag itself stays until you move or type.
    screen:SetScript("OnMouseDown", function() ns.StopAFKScreen() end)

    local panel = CreateFrame("Frame", nil, screen)
    panel:SetPoint("BOTTOMLEFT")
    panel:SetPoint("BOTTOMRIGHT")
    panel:SetHeight(130)
    screen.panel = panel

    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(ns.PANEL.r, ns.PANEL.g, ns.PANEL.b, ns.PANEL.a)

    -- Soft fade above the panel into the scene.
    local fade = screen:CreateTexture(nil, "BACKGROUND")
    fade:SetPoint("BOTTOMLEFT", panel, "TOPLEFT")
    fade:SetPoint("BOTTOMRIGHT", panel, "TOPRIGHT")
    fade:SetHeight(120)
    fade:SetColorTexture(1, 1, 1, 1)
    if CreateColor and fade.SetGradient then
        local p = ns.PANEL
        fade:SetGradient("VERTICAL", CreateColor(p.r, p.g, p.b, p.a), CreateColor(p.r, p.g, p.b, 0))
    else
        fade:Hide()
    end

    screen.line = panel:CreateTexture(nil, "ARTWORK")
    screen.line:SetPoint("TOPLEFT")
    screen.line:SetPoint("TOPRIGHT")
    screen.line:SetHeight(2)
    screen.line:SetColorTexture(1, 1, 1, 1)

    local logo = panel:CreateTexture(nil, "ARTWORK")
    logo:SetTexture(ns.media.logo)
    logo:SetSize(84, 84)
    logo:SetPoint("LEFT", panel, "LEFT", 36, 0)

    screen.name = panel:CreateFontString(nil, "OVERLAY")
    ns.SetFont(screen.name, 30)
    screen.name:SetPoint("TOPLEFT", logo, "TOPRIGHT", 20, -6)

    screen.info = panel:CreateFontString(nil, "OVERLAY")
    ns.SetFont(screen.info, 15)
    screen.info:SetTextColor(0.85, 0.85, 0.88)
    screen.info:SetPoint("TOPLEFT", screen.name, "BOTTOMLEFT", 0, -8)

    screen.guild = panel:CreateFontString(nil, "OVERLAY")
    ns.SetFont(screen.guild, 13)
    screen.guild:SetTextColor(0.6, 0.6, 0.65)
    screen.guild:SetPoint("TOPLEFT", screen.info, "BOTTOMLEFT", 0, -6)

    screen.clock = panel:CreateFontString(nil, "OVERLAY")
    ns.SetFont(screen.clock, 34)
    screen.clock:SetTextColor(1, 1, 1)
    screen.clock:SetPoint("RIGHT", panel, "RIGHT", -40, 10)

    local awayLabel = panel:CreateFontString(nil, "OVERLAY")
    ns.SetFont(awayLabel, 13)
    awayLabel:SetTextColor(0.6, 0.6, 0.65)
    awayLabel:SetText(L["AWAY"])
    awayLabel:SetPoint("TOPRIGHT", screen.clock, "BOTTOMRIGHT", -70, -8)

    screen.away = panel:CreateFontString(nil, "OVERLAY")
    ns.SetFont(screen.away, 13)
    screen.away:SetPoint("LEFT", awayLabel, "RIGHT", 8, 0)

    -- The character, standing on the panel at the right.
    local ok, model = pcall(CreateFrame, "PlayerModel", nil, screen)
    if ok and model then
        model:SetSize(420, 520)
        model:SetPoint("BOTTOMRIGHT", panel, "TOPRIGHT", -140, -60)
        screen.model = model
    end
end

-- The screen is laid out in UI units, but WorldFrame is not scaled with the
-- UI; match UIParent's scale so sizes and fonts look the same.
local function Show()
    if not screen then Build() end
    screen:SetScale(UIParent:GetEffectiveScale() / WorldFrame:GetEffectiveScale())
    FillCharacter()
    startedAt = GetTime()
    Tick()
    if not ticker and C_Timer and C_Timer.NewTicker then ticker = C_Timer.NewTicker(1, Tick) end
    screen:Show()
    UIParent:SetAlpha(0)
    if CanSpin() then MoveViewLeftStart(SPIN_SPEED) end
    active = true
end

function ns.StopAFKScreen()
    if not active then return end
    active = false
    if ticker then
        ticker:Cancel()
        ticker = nil
    end
    if type(MoveViewLeftStop) == "function" then MoveViewLeftStop() end
    UIParent:SetAlpha(1)
    if screen then screen:Hide() end
end

-- Shown for a few seconds from /aui afk, to see it without going AFK.
function ns.PreviewAFKScreen()
    if InCombatLockdown() then return end
    Show()
    if C_Timer and C_Timer.After then C_Timer.After(10, function() ns.StopAFKScreen() end) end
end

local function IsAFK()
    if type(UnitIsAFK) ~= "function" then return false end
    local afk = UnitIsAFK("player")
    if ns.IsSecret(afk) then return false end
    return afk and true or false
end

local function Update()
    if Enabled() and IsAFK() and not InCombatLockdown() and not UnitAffectingCombat("player") then
        if not active then Show() end
    else
        ns.StopAFKScreen()
    end
end

ns.On("PLAYER_FLAGS_CHANGED", function(unit)
    if unit == nil or unit == "player" then Update() end
end)
-- Combat always ends it at once.
ns.On("PLAYER_REGEN_DISABLED", function() ns.StopAFKScreen() end)
-- A loading screen while AFK (summons, logout countdown) ends it too.
ns.On("PLAYER_LEAVING_WORLD", function() ns.StopAFKScreen() end)
