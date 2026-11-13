local addonName, ns = ...

-------------------------------------------------------------------------------
--  First-run tour. Once after installing (and again with /aui tour): a few
--  short steps, each highlighting one part of the layout that is easy to miss,
--  with a Next button. Steps for parts that were not installed are left out.
--
--  The highlight is this addon's own frame, placed at the target's position on
--  screen; it is never anchored to the target, since some targets (the action
--  bar) are secure frames. The tour only starts out of combat and ends when
--  combat starts.
--
--  RETEST after an EllesmereUI update (read from 9.8.4): the side bar is
--  EllesmereUI's action bar frame "EABBar_Bar6"
--  (EUI_ActionBars_Bars.lua: "EABBar_" .. key).
-------------------------------------------------------------------------------

local L = ns.L

local tour, steps, index

-- A frame's rectangle in UIParent units: left, bottom, width, height.
local function Rect(frame)
    if type(frame) ~= "table" or not frame.GetLeft or not frame:IsShown() then return nil end
    local l, b, w, h = frame:GetLeft(), frame:GetBottom(), frame:GetWidth(), frame:GetHeight()
    if not (l and b and w and h) or w <= 0 or h <= 0 then return nil end
    local k = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    return l * k, b * k, w * k, h * k
end

local function AnyCombatHiding()
    local combat = ns.db.install.combat
    if type(combat) ~= "table" then return false end
    for _, on in pairs(combat) do
        if on then return true end
    end
    return false
end

local function BuildSteps()
    local db = ns.db
    local list = {}
    if db.bar.enabled then
        list[#list + 1] = {
            title = "Menu bar",
            text = "Micro menu, durability, professions, gold and the clock. Right-click a profession for First Aid or Cooking. Hover the experience bar for rested experience; at max level it shows your watched reputation.",
            target = function()
                local h = ns.InfoBarHeight()
                if db.bar.position == "TOP" then return 0, UIParent:GetHeight() - h, UIParent:GetWidth(), h end
                return 0, 0, UIParent:GetWidth(), h
            end,
        }
    end
    if db.install.actionBars then
        list[#list + 1] = {
            title = "Side bar",
            text = "Twelve more action buttons next to the chat. They only show while the mouse is over them.",
            target = function() return Rect(_G.EABBar_Bar6) end,
        }
    end
    if AnyCombatHiding() then
        list[#list + 1] = {
            title = "Out of combat",
            text = "Some parts of the screen are hidden while you are out of combat. They come back in a fight, and whenever the mouse is over them. Change this with /aui install.",
        }
    end
    list[#list + 1] = {
        title = "Settings",
        text = "Type /aui for AritlokUI's settings inside EllesmereUI's options: theme, accent color, AFK screen and the changelog. /aui install runs the installer again, /aui tour shows this tour.",
        target = function() return Rect(_G.AddonCompartmentFrame) end,
    }
    return list
end

local function Border(parent, r, g, b)
    local edges = {}
    for i = 1, 4 do
        edges[i] = parent:CreateTexture(nil, "OVERLAY")
        edges[i]:SetColorTexture(r, g, b, 1)
    end
    edges[1]:SetPoint("TOPLEFT")
    edges[1]:SetPoint("TOPRIGHT")
    edges[1]:SetHeight(2)
    edges[2]:SetPoint("BOTTOMLEFT")
    edges[2]:SetPoint("BOTTOMRIGHT")
    edges[2]:SetHeight(2)
    edges[3]:SetPoint("TOPLEFT")
    edges[3]:SetPoint("BOTTOMLEFT")
    edges[3]:SetWidth(2)
    edges[4]:SetPoint("TOPRIGHT")
    edges[4]:SetPoint("BOTTOMRIGHT")
    edges[4]:SetWidth(2)
    return edges
end

local function Button(parent, label)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(96, 24)
    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetAllPoints()
    button.bg:SetColorTexture(1, 1, 1, 0.08)
    button.text = button:CreateFontString(nil, "OVERLAY")
    ns.SetFont(button.text, 12)
    button.text:SetPoint("CENTER")
    button.text:SetText(label)
    button:SetScript("OnEnter", function(self) self.bg:SetColorTexture(1, 1, 1, 0.16) end)
    button:SetScript("OnLeave", function(self) self.bg:SetColorTexture(1, 1, 1, 0.08) end)
    return button
end

local function Build()
    tour = CreateFrame("Frame", "AritlokUITour", UIParent)
    tour:SetAllPoints(UIParent)
    tour:SetFrameStrata("FULLSCREEN_DIALOG")
    tour:Hide()

    -- The highlight box, pulsing gently.
    tour.box = CreateFrame("Frame", nil, tour)
    tour.box.edges = Border(tour.box, 1, 1, 1)
    local pulse = tour.box:CreateAnimationGroup()
    pulse:SetLooping("BOUNCE")
    local fade = pulse:CreateAnimation("Alpha")
    fade:SetFromAlpha(1)
    fade:SetToAlpha(0.35)
    fade:SetDuration(0.8)
    pulse:Play()

    -- The callout.
    local card = CreateFrame("Frame", nil, tour)
    card:SetSize(380, 150)
    card:SetClampedToScreen(true)
    card:EnableMouse(true)
    tour.card = card
    local bg = card:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(ns.PANEL.r, ns.PANEL.g, ns.PANEL.b, 0.97)
    card.line = card:CreateTexture(nil, "ARTWORK")
    card.line:SetPoint("TOPLEFT")
    card.line:SetPoint("TOPRIGHT")
    card.line:SetHeight(2)
    card.line:SetColorTexture(1, 1, 1, 1)

    card.count = card:CreateFontString(nil, "OVERLAY")
    ns.SetFont(card.count, 11)
    card.count:SetTextColor(0.6, 0.6, 0.65)
    card.count:SetPoint("TOPRIGHT", -14, -14)

    card.title = card:CreateFontString(nil, "OVERLAY")
    ns.SetFont(card.title, 16)
    card.title:SetPoint("TOPLEFT", 14, -14)

    card.text = card:CreateFontString(nil, "OVERLAY")
    ns.SetFont(card.text, 12)
    card.text:SetTextColor(0.86, 0.86, 0.88)
    card.text:SetJustifyH("LEFT")
    card.text:SetJustifyV("TOP")
    card.text:SetWordWrap(true)
    card.text:SetSpacing(2)
    card.text:SetPoint("TOPLEFT", card.title, "BOTTOMLEFT", 0, -10)
    card.text:SetWidth(352)

    card.next = Button(card, L["Next"])
    card.next:SetPoint("BOTTOMRIGHT", -14, 14)
    card.next:SetScript("OnClick", function() ns.TourNext() end)

    card.skip = Button(card, L["Skip tour"])
    card.skip:SetPoint("BOTTOMLEFT", 14, 14)
    card.skip:SetScript("OnClick", function() ns.StopTour() end)
end

local function ShowStep()
    local step = steps[index]
    local card = tour.card
    local r, g, b = ns.GetAccent()
    card.line:SetColorTexture(r, g, b, 1)
    for i = 1, 4 do
        tour.box.edges[i]:SetColorTexture(r, g, b, 1)
    end
    card.title:SetText(L[step.title])
    card.title:SetTextColor(r, g, b)
    card.text:SetText(L[step.text])
    card.count:SetText(string.format("%d / %d", index, #steps))
    card.next.text:SetText(index == #steps and L["Done"] or L["Next"])
    card.skip:SetShown(index < #steps)
    card:SetHeight(14 + (card.title:GetStringHeight() or 16) + 10 + (card.text:GetStringHeight() or 40) + 16 + 24 + 14)

    -- Highlight the target and put the card beside it: above a target in
    -- the lower half of the screen, below one in the upper half.
    card:ClearAllPoints()
    local l, bottom, w, h
    if step.target then
        l, bottom, w, h = step.target()
    end
    if l then
        local pad = 4
        tour.box:ClearAllPoints()
        tour.box:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", l - pad, bottom - pad)
        tour.box:SetSize(w + 2 * pad, h + 2 * pad)
        tour.box:Show()
        local centerX = l + w / 2
        local screenW = UIParent:GetWidth()
        local anchor = (centerX < screenW / 3) and "LEFT" or (centerX > screenW * 2 / 3) and "RIGHT" or ""
        if bottom + h / 2 < UIParent:GetHeight() / 2 then
            card:SetPoint("BOTTOM" .. anchor, tour.box, "TOP" .. anchor, 0, 12)
        else
            card:SetPoint("TOP" .. anchor, tour.box, "BOTTOM" .. anchor, 0, -12)
        end
    else
        tour.box:Hide()
        card:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    end
end

function ns.StopTour()
    if tour then tour:Hide() end
    steps, index = nil, nil
end

function ns.TourNext()
    if not steps then return end
    if index >= #steps then
        ns.StopTour()
        return
    end
    index = index + 1
    ShowStep()
end

function ns.StartTour()
    if InCombatLockdown() or not ns.db then return false end
    if not tour then Build() end
    steps = BuildSteps()
    index = 1
    ns.db.tourSeen = true
    tour:Show()
    ShowStep()
    return true
end

-- Once, on the first login after installing.
local offered = false
ns.On("PLAYER_ENTERING_WORLD", function()
    if offered then return end
    offered = true
    local db = ns.db
    if not db or not db.installed or db.tourSeen then return end
    -- After EllesmereUI has placed its bars.
    if C_Timer and C_Timer.After then C_Timer.After(5, function() ns.RunOutOfCombat(ns.StartTour) end) end
end)

ns.On("PLAYER_REGEN_DISABLED", function() ns.StopTour() end)
