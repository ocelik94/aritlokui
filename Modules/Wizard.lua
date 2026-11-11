local addonName, ns = ...

-------------------------------------------------------------------------------
--  Installer window
--  A five-step setup: welcome, theme, what to theme, info bar, install. It is
--  this addon's own frame (no StaticPopup, no Blizzard panel code, nothing
--  protected), so it can be shown at any time; the install step itself still
--  refuses in combat and says so.
--
--  The last page's Reload button does nothing but reload: on Forever addon
--  code may reload only as the first thing a click does.
-------------------------------------------------------------------------------

local STEPS = 5
local DONE = STEPS + 1
local WIDTH, HEIGHT = 640, 430

local frame
local pages = {}
local step = 1
local refreshers = {} -- per-page functions run each time the page is shown

local TITLES = {
    "Welcome",
    "Choose a theme",
    "What to theme",
    "Bottom bar",
    "Install",
    "Finished",
}

-------------------------------------------------------------------------------
--  Small widgets
-------------------------------------------------------------------------------
local function Label(parent, size, r, g, b)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    ns.SetFont(fs, size)
    fs:SetTextColor(r or 0.9, g or 0.9, b or 0.92)
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")
    return fs
end

local function Paragraph(parent, text, y)
    local fs = Label(parent, 13)
    fs:SetPoint("TOPLEFT", 0, y)
    fs:SetPoint("TOPRIGHT", 0, y)
    fs:SetSpacing(4)
    fs:SetText(text)
    return fs
end

-- A check row: box, title and a dimmer description line.
local function Check(parent, y, title, description, get, set)
    local row = CreateFrame("Button", nil, parent)
    row:SetPoint("TOPLEFT", 0, y)
    row:SetPoint("TOPRIGHT", 0, y)
    row:SetHeight(44)

    local hover = row:CreateTexture(nil, "BACKGROUND")
    hover:SetAllPoints()
    hover:SetColorTexture(1, 1, 1, 0.04)
    hover:Hide()

    local box = row:CreateTexture(nil, "BORDER")
    box:SetSize(18, 18)
    box:SetPoint("LEFT", 8, 0)
    box:SetColorTexture(0.16, 0.17, 0.2, 1)

    local mark = row:CreateTexture(nil, "ARTWORK")
    mark:SetPoint("TOPLEFT", box, "TOPLEFT", 3, -3)
    mark:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -3, 3)
    mark:SetColorTexture(1, 1, 1, 1)

    local name = Label(row, 14, 1, 1, 1)
    name:SetPoint("TOPLEFT", box, "TOPRIGHT", 12, 6)
    name:SetText(title)

    local desc = Label(row, 11, 0.62, 0.64, 0.68)
    desc:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -3)
    desc:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    desc:SetText(description)

    local function Paint()
        local lr, lg, lb, rr, rg, rb = ns.ClassGradient()
        ns.HGradient(mark, lr, lg, lb, 1, rr, rg, rb, 1)
        mark:SetShown(get() and true or false)
    end

    row:SetScript("OnEnter", function() hover:Show() end)
    row:SetScript("OnLeave", function() hover:Hide() end)
    row:SetScript("OnClick", function()
        set(not get())
        Paint()
    end)
    row.Paint = Paint
    Paint()
    return row
end

-- A theme card with three sample bars.
local function ThemeCard(parent, x, key, title, description)
    local card = CreateFrame("Button", nil, parent)
    card:SetSize(292, 190)
    card:SetPoint("TOPLEFT", x, -4)

    local bg = card:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.075, 0.08, 0.095, 1)

    card.outline = card:CreateTexture(nil, "BORDER")
    card.outline:SetPoint("BOTTOMLEFT")
    card.outline:SetPoint("BOTTOMRIGHT")
    card.outline:SetHeight(3)
    card.outline:SetColorTexture(1, 1, 1, 1)

    card.bars = {}
    local widths = { 252, 190, 120 }
    for i = 1, 3 do
        local back = card:CreateTexture(nil, "BORDER")
        back:SetSize(252, 18)
        back:SetPoint("TOPLEFT", 20, -20 - (i - 1) * 26)
        back:SetColorTexture(0.03, 0.03, 0.04, 1)
        local bar = card:CreateTexture(nil, "ARTWORK")
        bar:SetSize(widths[i], 18)
        bar:SetPoint("TOPLEFT", back, "TOPLEFT", 0, 0)
        bar:SetColorTexture(1, 1, 1, 1)
        card.bars[i] = bar
    end

    local name = Label(card, 15, 1, 1, 1)
    name:SetPoint("TOPLEFT", 20, -106)
    name:SetText(title)

    local desc = Label(card, 11, 0.62, 0.64, 0.68)
    desc:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -6)
    desc:SetPoint("RIGHT", card, "RIGHT", -20, 0)
    desc:SetSpacing(3)
    desc:SetText(description)

    card.key = key
    return card
end

-------------------------------------------------------------------------------
--  Pages
-------------------------------------------------------------------------------
local function NewPage(index)
    local page = CreateFrame("Frame", nil, frame)
    page:SetPoint("TOPLEFT", 28, -104)
    page:SetPoint("BOTTOMRIGHT", -28, 64)
    page:Hide()
    pages[index] = page
    return page
end

local function BuildWelcome()
    local page = NewPage(1)
    Paragraph(
        page,
        "This sets up the Aritlok look on top of EllesmereUI.|n|n"
            .. '- Your current EllesmereUI profile is copied to a new one named "'
            .. ns.PROFILE_NAME
            .. '". The profile you use now is not changed.|n'
            .. "- On the next pages you choose the theme and what gets themed.|n"
            .. "- The last step asks for one UI reload.|n|n"
            .. "Run it again at any time with |cffffffff/aui install|r. "
            .. "Go back to your old profile with |cffffffff/aui restore|r.",
        0
    )
end

local function BuildTheme()
    local page = NewPage(2)
    local cards = {
        ThemeCard(page, 0, "gradient", "Gradient", "Class-coloured bars that run from a deep left end to a bright right end."),
        ThemeCard(page, 292, "dark", "Dark", "Flat dark bars with class-coloured names. Uses EllesmereUI's dark theme."),
    }
    cards[2]:ClearAllPoints()
    cards[2]:SetPoint("TOPRIGHT", 0, -4)

    local function Paint()
        local lr, lg, lb, rr, rg, rb = ns.ClassGradient()
        for i = 1, #cards do
            local card = cards[i]
            local selected = (ns.db.theme == card.key)
            for j = 1, #card.bars do
                if card.key == "gradient" then
                    ns.HGradient(card.bars[j], lr, lg, lb, 1, rr, rg, rb, 1)
                else
                    ns.HGradient(card.bars[j], 0.13, 0.14, 0.16, 1, 0.2, 0.21, 0.24, 1)
                end
            end
            if selected then
                ns.HGradient(card.outline, lr, lg, lb, 1, rr, rg, rb, 1)
            else
                ns.HGradient(card.outline, 0.2, 0.21, 0.24, 1, 0.2, 0.21, 0.24, 1)
            end
            card:SetAlpha(selected and 1 or 0.6)
        end
    end

    for i = 1, #cards do
        cards[i]:SetScript("OnClick", function(self)
            ns.db.theme = self.key
            ns.RefreshShades()
            Paint()
        end)
    end
    refreshers[2] = Paint
end

local function BuildParts()
    local page = NewPage(3)
    local want = ns.db.install
    local rows = {
        Check(
            page,
            0,
            "Unit frames",
            "ToxiUI layout: 300 x 36 player and target either side of a free centre, texts above and below the bar, power bar in the middle.",
            function() return want.unitFrames end,
            function(v) want.unitFrames = v end
        ),
        Check(
            page,
            -46,
            "Action bars",
            "ToxiUI layout: wide 36 x 29 buttons, bars 1-3 stacked at the bottom centre, bars 4 and 5 as 4 x 3 blocks beside them.",
            function() return want.actionBars end,
            function(v) want.actionBars = v end
        ),
        Check(
            page,
            -92,
            "Bottom bar from EllesmereUI DataBars",
            "Icon micro menu, clock, gold, durability and more. Off uses the simpler built-in bar.",
            function() return want.dataBar end,
            function(v) want.dataBar = v end
        ),
        Check(
            page,
            -184,
            "Pixel-perfect UI scale",
            "One UI unit per screen pixel: 0.5333 at 2560 x 1440. Everything gets smaller and sharper.",
            function() return want.scale end,
            function(v) want.scale = v end
        ),
        Check(
            page,
            -138,
            "Flat style, font, accent and screen-edge layout",
            "Flat look, Monaspace font, class-colour accent, chat bottom left; minimap, quests, tooltip and meters on the right.",
            function() return want.style end,
            function(v)
                want.style = v
                want.accent = v
                want.chat = v
                want.minimap = v
                want.rightSide = v
                want.font = v
            end
        ),
    }
    refreshers[3] = function()
        for i = 1, #rows do
            rows[i].Paint()
        end
    end
end

local function BuildBar()
    local page = NewPage(4)
    local cfg = ns.db.bar
    local rows = {
        Check(
            page,
            0,
            "Show the bottom bar",
            "The strip along the screen edge with its fading backdrop.",
            function() return cfg.enabled end,
            function(v)
                cfg.enabled = v
                ns.ApplyInfoBar()
            end
        ),
        Check(
            page,
            -46,
            "Put it at the top of the screen",
            "Off keeps it at the bottom.",
            function() return cfg.position == "TOP" end,
            function(v)
                cfg.position = v and "TOP" or "BOTTOM"
                ns.ApplyInfoBar()
            end
        ),
        Check(
            page,
            -92,
            "Class-colour wash",
            "A soft class-coloured glow at both ends of the bar.",
            function() return cfg.classWash end,
            function(v)
                cfg.classWash = v
                ns.ApplyInfoBar()
            end
        ),
        Check(page, -138, "24-hour clock", "Off shows AM / PM.", function() return cfg.clock24 end, function(v)
            cfg.clock24 = v
            ns.ApplyInfoBar()
        end),
    }
    refreshers[4] = function()
        for i = 1, #rows do
            rows[i].Paint()
        end
    end
end

local function BuildInstall()
    local page = NewPage(5)
    local summary = Paragraph(page, "", 0)
    page.status = Label(page, 12, 1, 0.35, 0.35)
    page.status:SetPoint("BOTTOMLEFT", 0, 0)
    page.status:SetPoint("BOTTOMRIGHT", 0, 0)

    refreshers[5] = function()
        local db = ns.db
        local want = db.install
        local parts = {}
        if want.unitFrames then parts[#parts + 1] = "unit frames" end
        if want.actionBars then parts[#parts + 1] = "action bars" end
        if want.dataBar then parts[#parts + 1] = "bottom bar" end
        if want.scale then parts[#parts + 1] = "pixel-perfect scale" end
        if want.style then parts[#parts + 1] = "flat style, accent, chat" end
        summary:SetText(
            "Ready to install.|n|n"
                .. "Theme:  |cffffffff"
                .. (db.theme == "dark" and "Dark" or "Gradient")
                .. "|r|n"
                .. "Themed:  |cffffffff"
                .. (#parts > 0 and table.concat(parts, ", ") or "nothing")
                .. "|r|n"
                .. "Bottom bar:  |cffffffff"
                .. (db.bar.enabled and string.lower(db.bar.position) or "off")
                .. "|r|n|n"
                .. 'Install copies your EllesmereUI profile to "'
                .. ns.PROFILE_NAME
                .. '" (or reuses it if it exists) and writes the settings there.'
        )
        page.status:SetText("")
    end
end

local function BuildDone()
    local page = NewPage(DONE)
    page.text = Paragraph(page, "", 0)
end

-------------------------------------------------------------------------------
--  Navigation
-------------------------------------------------------------------------------
local function Show(index)
    step = index
    for i = 1, DONE do
        if pages[i] then pages[i]:SetShown(i == index) end
    end

    local lr, lg, lb, rr, rg, rb = ns.ClassGradient()
    frame.heading:SetText(ns.GradientText(TITLES[index], rr, rg, rb, 1, 1, 1))
    if index <= STEPS then
        frame.count:SetText("Step " .. index .. " of " .. STEPS)
    else
        frame.count:SetText("")
    end
    frame.progress:SetValue(index > STEPS and STEPS or index)
    local fill = frame.progress:GetStatusBarTexture()
    if fill then ns.HGradient(fill, lr, lg, lb, 1, rr, rg, rb, 1) end

    frame.back:SetShown(index > 1 and index <= STEPS)
    frame.next:SetShown(index <= STEPS)
    frame.next.label:SetText(index == STEPS and "Install" or "Next")
    frame.reload:SetShown(index == DONE)
    frame.later:SetShown(index == DONE)

    if refreshers[index] then refreshers[index]() end
end

local function RunInstall()
    local ok, message = ns.Install(ns.db.theme, true)
    if not ok then
        pages[STEPS].status:SetText("Not installed: " .. (message or "unknown reason."))
        return
    end
    pages[DONE].text:SetText(
        'The theme is written to the EllesmereUI profile "'
            .. ns.PROFILE_NAME
            .. '".|n|n'
            .. (message and (message .. "|n|n") or "")
            .. "Reload the UI to apply it. Until then EllesmereUI still shows the old layout.|n|n"
            .. "Afterwards: |cffffffff/aui|r opens the settings, |cffffffff/eui|r opens EllesmereUI, "
            .. "|cffffffff/aui restore|r goes back to your old profile."
    )
    Show(DONE)
end

-------------------------------------------------------------------------------
--  Window
-------------------------------------------------------------------------------
local function Build()
    frame = CreateFrame("Frame", "AritlokUIInstaller", UIParent)
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetPoint("CENTER", 0, 40)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.04, 0.045, 0.055, 0.97)

    local lr, lg, lb, rr, rg, rb = ns.ClassGradient()

    -- Header wash: class gradient fading down into the window.
    local wash = frame:CreateTexture(nil, "BORDER")
    wash:SetPoint("TOPLEFT")
    wash:SetPoint("TOPRIGHT")
    wash:SetHeight(84)
    wash:SetColorTexture(1, 1, 1, 1)
    if CreateColor then
        wash:SetGradient("VERTICAL", CreateColor(lr, lg, lb, 0), CreateColor(rr, rg, rb, 0.22))
    else
        wash:SetVertexColor(lr, lg, lb, 0.1)
    end

    local band = frame:CreateTexture(nil, "ARTWORK")
    band:SetPoint("TOPLEFT")
    band:SetPoint("TOPRIGHT")
    band:SetHeight(3)
    band:SetColorTexture(1, 1, 1, 1)
    ns.HGradient(band, lr, lg, lb, 1, rr, rg, rb, 1)

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(36, 36)
    icon:SetPoint("TOPLEFT", 28, -22)
    icon:SetTexture(ns.media.icon)

    local title = Label(frame, 12, 0.62, 0.64, 0.68)
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -1)
    title:SetText("ARITLOK UI  -  INSTALLER")

    frame.heading = Label(frame, 22, 1, 1, 1)
    frame.heading:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)

    frame.count = Label(frame, 12, 0.62, 0.64, 0.68)
    frame.count:SetPoint("TOPRIGHT", -56, -30)
    frame.count:SetJustifyH("RIGHT")

    local close = CreateFrame("Button", nil, frame)
    close:SetSize(24, 24)
    close:SetPoint("TOPRIGHT", -14, -18)
    local x = Label(close, 16, 0.7, 0.7, 0.74)
    x:SetPoint("CENTER")
    x:SetText("x")
    close:SetScript("OnEnter", function() x:SetTextColor(1, 1, 1) end)
    close:SetScript("OnLeave", function() x:SetTextColor(0.7, 0.7, 0.74) end)
    close:SetScript("OnClick", function() frame:Hide() end)

    frame.progress = CreateFrame("StatusBar", nil, frame)
    frame.progress:SetPoint("TOPLEFT", 28, -78)
    frame.progress:SetPoint("TOPRIGHT", -28, -78)
    frame.progress:SetHeight(4)
    frame.progress:SetStatusBarTexture(ns.media.white)
    frame.progress:SetMinMaxValues(0, STEPS)
    local track = frame.progress:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    track:SetColorTexture(1, 1, 1, 0.07)

    frame.next = ns.MakeButton(frame, "Next", rr * 0.55, rg * 0.55, rb * 0.55)
    frame.next:SetPoint("BOTTOMRIGHT", -28, 22)
    frame.next:SetScript("OnClick", function()
        if step < STEPS then
            Show(step + 1)
        elseif step == STEPS then
            RunInstall()
        end
    end)

    frame.back = ns.MakeButton(frame, "Back", 0.2, 0.21, 0.24)
    frame.back:SetPoint("RIGHT", frame.next, "LEFT", -8, 0)
    frame.back:SetScript("OnClick", function()
        if step > 1 then Show(step - 1) end
    end)

    frame.reload = ns.MakeButton(frame, "Reload UI", rr * 0.55, rg * 0.55, rb * 0.55)
    frame.reload:SetPoint("BOTTOMRIGHT", -28, 22)
    -- The reload is the only thing this click does.
    frame.reload:SetScript("OnClick", function() ReloadUI() end)

    frame.later = ns.MakeButton(frame, "Later", 0.2, 0.21, 0.24)
    frame.later:SetPoint("RIGHT", frame.reload, "LEFT", -8, 0)
    frame.later:SetScript("OnClick", function() frame:Hide() end)

    BuildWelcome()
    BuildTheme()
    BuildParts()
    BuildBar()
    BuildInstall()
    BuildDone()
end

function ns.OpenInstaller()
    if not ns.db then return end
    if not frame then Build() end
    ns.db.wizardSeen = true
    Show(1)
    frame:Show()
end

-------------------------------------------------------------------------------
--  First run
-------------------------------------------------------------------------------
-- EllesmereUI.RegisterExternalInstaller is deliberately NOT called: it keeps
-- EllesmereUI's own first-run pickers quiet until a profile import stamps
-- them done, and this installer copies a profile instead of importing one.
local offered = false
ns.On("PLAYER_ENTERING_WORLD", function()
    if offered then return end
    offered = true
    local db = ns.db
    if not db or db.installed or db.wizardSeen then return end
    if C_Timer and C_Timer.After then C_Timer.After(3, function() ns.RunOutOfCombat(ns.OpenInstaller) end) end
end)
