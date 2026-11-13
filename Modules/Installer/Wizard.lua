local addonName, ns = ...

-------------------------------------------------------------------------------
--  Installer window
--  Sidebar with the steps on the left, one page at a time on the right.
--  Steps already visited can be clicked in the sidebar; Back and Continue sit
--  in the footer.
--
--  It is this addon's own frame (no StaticPopup, no Blizzard panel code,
--  nothing protected), so it can be shown at any time; the install itself
--  still refuses in combat and says so.
--
--  The closing page's button does nothing but reload: on Forever addon code
--  may reload only as the first thing a click does.
--
--  Each page opens with a short paragraph (and, where it matters, a
--  highlighted note), then its choices with one line each. The hint line at
--  the bottom of a page carries errors.
-------------------------------------------------------------------------------

local I = ns.Installer
local L = ns.L

local WIDTH, HEIGHT, SIDEBAR = 760, 580, 200
local PAD = 36
local HEADER, FOOTER = 92, 70

-- Sidebar name and page heading are the same word.
local STEPS = { "Welcome", "Profile", "Theme", "Layout", "Look", "Combat", "Addons", "Install" }

-- What each page opens with: a short paragraph, and optionally a highlighted
-- note under it.
local INTROS = {
    {
        "This installer sets up AritlokUI on top of EllesmereUI in a few steps. Your current profile is copied, never changed.",
        "Important: after a larger AritlokUI update you may need to run the installer again.",
    },
    {
        "AritlokUI writes its settings into a copy of your current EllesmereUI profile. Use the shared profile, or create one with its own name.",
    },
    { "Pick how the unit frame bars are colored. You can switch later by running the installer again." },
    { "Choose which parts of the screen are arranged. Anything you switch off stays exactly as it is now." },
    {
        "Style, font, accent color and scale.",
        "Important: the UI scale applies to your whole account, not just this profile.",
    },
    { "Switch on what should be hidden while you are out of combat. It shows again in a fight, and whenever the mouse is over it." },
    { "AritlokUI can adjust other addons so they match." },
    { "Check your choices, then press Install. Nothing is changed before that." },
}
local PAGE_WELCOME, PAGE_PROFILE, PAGE_THEME, PAGE_LAYOUT, PAGE_LOOK, PAGE_COMBAT, PAGE_ADDONS, PAGE_INSTALL = 1, 2, 3, 4, 5, 6, 7, 8
local DONE = #STEPS + 1

-- Palette
local TEXT = { 0.93, 0.94, 0.96 }
local DIM = { 0.58, 0.61, 0.67 }
local FAINT = { 0.36, 0.39, 0.45 }
local WARN = { 1, 0.72, 0.3 }
local BAD = { 1, 0.42, 0.42 }
-- An unlit disc. Opaque on purpose: a texture's vertex alpha is the same value
-- as its alpha, and a page's fade-in animation leaves that at 1, which turned
-- a "white at 12%" radio marker into a solid white disc.
local DISC_OFF = { 0.16, 0.17, 0.2 }

local frame
local pages = {}
local refreshers = {} -- per-page functions run each time the page is shown
local stepItems = {}
local step = 1
local reached = 1 -- furthest step visited; the sidebar lets you jump back to any of them

-------------------------------------------------------------------------------
--  Drawing helpers
-------------------------------------------------------------------------------
local function Solid(parent, layer, r, g, b, a)
    local t = parent:CreateTexture(nil, layer)
    t:SetColorTexture(r, g, b, a or 1)
    return t
end

-- One line of text. Labels never wrap unless `wrap` is set, so a long
-- translation is cut with "..." instead of spilling out of its box.
local function Label(parent, size, color, justify, wrap)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    ns.SetFont(fs, size)
    color = color or TEXT
    fs:SetTextColor(color[1], color[2], color[3])
    fs:SetJustifyH(justify or "LEFT")
    fs:SetJustifyV("TOP")
    fs:SetWordWrap(wrap and true or false)
    return fs
end

-- Paints a texture with the player's class gradient.
local function Gradient(texture, alpha)
    local lr, lg, lb, rr, rg, rb = ns.ClassGradient()
    texture:SetColorTexture(1, 1, 1, 1)
    ns.HGradient(texture, lr, lg, lb, alpha or 1, rr, rg, rb, alpha or 1)
end

-- Paints a texture one flat color. A gradient is stored as per-corner vertex
-- colors, which outlive SetColorTexture, so they are reset as well.
local function Flat(texture, r, g, b, a)
    texture:SetColorTexture(r, g, b, a or 1)
    texture:SetVertexColor(1, 1, 1, 1)
end

-- A 1-unit border made of four strips.
local function Border(parent)
    local b = {}
    b.top = Solid(parent, "BORDER", 1, 1, 1, 1)
    b.top:SetPoint("TOPLEFT")
    b.top:SetPoint("TOPRIGHT")
    b.top:SetHeight(1)
    b.bottom = Solid(parent, "BORDER", 1, 1, 1, 1)
    b.bottom:SetPoint("BOTTOMLEFT")
    b.bottom:SetPoint("BOTTOMRIGHT")
    b.bottom:SetHeight(1)
    b.left = Solid(parent, "BORDER", 1, 1, 1, 1)
    b.left:SetPoint("TOPLEFT")
    b.left:SetPoint("BOTTOMLEFT")
    b.left:SetWidth(1)
    b.right = Solid(parent, "BORDER", 1, 1, 1, 1)
    b.right:SetPoint("TOPRIGHT")
    b.right:SetPoint("BOTTOMRIGHT")
    b.right:SetWidth(1)

    function b:Set(r, g, bl, a)
        Flat(self.top, r, g, bl, a)
        Flat(self.bottom, r, g, bl, a)
        Flat(self.left, r, g, bl, a)
        Flat(self.right, r, g, bl, a)
    end
    function b:SetGradient()
        local lr, lg, lb, rr, rg, rb = ns.ClassGradient()
        Gradient(self.top)
        Gradient(self.bottom)
        Flat(self.left, lr, lg, lb, 1)
        Flat(self.right, rr, rg, rb, 1)
    end
    return b
end

-- Lines centerd on `parent` (a frame), given as { x1, y1, x2, y2 } in halves
-- of `size`. Returns them so they can be shown and hidden together.
local function Lines(parent, size, thickness, r, g, b, segments)
    local lines = {}
    if not parent.CreateLine then return lines end
    local s = size / 2
    for i = 1, #segments do
        local seg = segments[i]
        local line = parent:CreateLine(nil, "OVERLAY")
        line:SetColorTexture(r, g, b, 1)
        line:SetThickness(thickness)
        line:SetStartPoint("CENTER", parent, seg[1] * s, seg[2] * s)
        line:SetEndPoint("CENTER", parent, seg[3] * s, seg[4] * s)
        lines[i] = line
    end
    return lines
end

local function Tick(parent, size, r, g, b)
    return Lines(parent, size, math.max(1.5, size / 6), r, g, b, { { -0.75, 0, -0.2, -0.55 }, { -0.2, -0.55, 0.8, 0.6 } })
end

local function Cross(parent, size, r, g, b) return Lines(parent, size, 1.5, r, g, b, { { -1, -1, 1, 1 }, { -1, 1, 1, -1 } }) end

local function SetShown(regions, shown)
    for i = 1, #regions do
        regions[i]:SetShown(shown)
    end
end

-- A disc (the circle texture).
local function Disc(parent, size)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(size, size)
    holder.fill = holder:CreateTexture(nil, "ARTWORK")
    holder.fill:SetAllPoints()
    holder.fill:SetTexture(ns.media.circle)
    return holder
end

-- primary: filled with the class gradient. Otherwise an outlined button.
-- The button grows to fit its (translated) label.
local function Button(parent, text, primary, minWidth)
    local button = CreateFrame("Button", nil, parent)

    local bg = Solid(button, "BACKGROUND", 1, 1, 1, 1)
    bg:SetAllPoints()
    if primary then
        Gradient(bg, 0.92)
    else
        Flat(bg, 1, 1, 1, 0.07)
        Border(button):Set(1, 1, 1, 0.22)
    end
    local hover = Solid(button, "HIGHLIGHT", 1, 1, 1, primary and 0.14 or 0.08)
    hover:SetAllPoints()

    button.label = Label(button, 13, primary and { 1, 1, 1 } or TEXT, "CENTER")
    button.label:SetPoint("CENTER", 0, 0)

    function button:SetLabel(key)
        self.label:SetText(L[key])
        self:SetSize(math.max(minWidth or 110, (self.label:GetStringWidth() or 0) + 36), 34)
    end
    button:SetLabel(text)

    button:SetScript("OnMouseDown", function() button.label:SetPoint("CENTER", 0, -1) end)
    button:SetScript("OnMouseUp", function() button.label:SetPoint("CENTER", 0, 0) end)
    return button
end

-------------------------------------------------------------------------------
--  Pages
-------------------------------------------------------------------------------
local function NewPage(index)
    local page = CreateFrame("Frame", nil, frame.content)
    page:SetPoint("TOPLEFT", PAD, -HEADER)
    page:SetPoint("BOTTOMRIGHT", -PAD, FOOTER + 8)
    page:Hide()

    -- Soft fade each time the page is shown.
    local group = page:CreateAnimationGroup()
    local fade = group:CreateAnimation("Alpha")
    fade:SetFromAlpha(0)
    fade:SetToAlpha(1)
    fade:SetDuration(0.18)
    fade:SetSmoothing("OUT")
    page.fade = group

    -- One line at the bottom of the page: the description of whatever the
    -- mouse is over, or an error.
    page.hint = Label(page, 11, DIM)
    page.hint:SetPoint("BOTTOMLEFT", 0, 0)
    page.hint:SetPoint("BOTTOMRIGHT", 0, 0)
    function page:SetHint(text, color)
        color = color or DIM
        self.hint:SetTextColor(color[1], color[2], color[3])
        self.hint:SetText(text or "")
    end

    -- Opening paragraph and optional note. page.top is where the page's own
    -- content starts.
    page.top = 0
    local intro = INTROS[index]
    if intro then
        local text = Label(page, 12, { 0.8, 0.82, 0.86 }, "LEFT", true)
        text:SetPoint("TOPLEFT", 0, 0)
        text:SetPoint("TOPRIGHT", 0, 0)
        text:SetSpacing(4)
        text:SetMaxLines(3)
        text:SetText(L[intro[1]])
        page.top = -62
        if intro[2] then
            local note = Label(page, 12, WARN, "LEFT", true)
            note:SetPoint("TOPLEFT", 0, -54)
            note:SetPoint("TOPRIGHT", 0, -54)
            note:SetSpacing(4)
            note:SetMaxLines(2)
            note:SetText(L[intro[2]])
            page.top = -100
        end
    end

    pages[index] = page
    return page
end

-- A setting row: title, an optional one-line description (English, translated
-- here) and a switch.
local function SwitchRow(page, y, title, description, get, set)
    local row = CreateFrame("Button", nil, page)
    row:SetPoint("TOPLEFT", 0, y)
    row:SetPoint("TOPRIGHT", 0, y)
    row:SetHeight(description and 52 or 40)

    local bg = Solid(row, "BACKGROUND", 1, 1, 1, 0.035)
    bg:SetAllPoints()
    local hover = Solid(row, "HIGHLIGHT", 1, 1, 1, 0.03)
    hover:SetAllPoints()
    local marker = Solid(row, "ARTWORK", 1, 1, 1, 1)
    marker:SetPoint("TOPLEFT")
    marker:SetPoint("BOTTOMLEFT")
    marker:SetWidth(2)

    local track = Solid(row, "ARTWORK", 1, 1, 1, 1)
    track:SetSize(36, 18)
    track:SetPoint("RIGHT", -16, 0)
    local knob = Solid(row, "OVERLAY", 1, 1, 1, 1)
    knob:SetSize(14, 14)

    local name = Label(row, 14, TEXT)
    if description then
        name:SetPoint("TOPLEFT", 16, -10)
    else
        name:SetPoint("LEFT", 16, 0)
    end
    name:SetPoint("RIGHT", track, "LEFT", -12, 0)
    name:SetText(L[title])

    if description then
        local desc = Label(row, 11, DIM)
        desc:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4)
        desc:SetPoint("RIGHT", track, "LEFT", -12, 0)
        desc:SetText(L[description])
    end

    local function Paint()
        local on = get() and true or false
        knob:ClearAllPoints()
        if on then
            Gradient(track)
            knob:SetPoint("RIGHT", track, "RIGHT", -2, 0)
            knob:SetColorTexture(1, 1, 1, 1)
            Gradient(marker)
            name:SetTextColor(TEXT[1], TEXT[2], TEXT[3])
        else
            Flat(track, 1, 1, 1, 0.1)
            knob:SetPoint("LEFT", track, "LEFT", 2, 0)
            knob:SetColorTexture(0.55, 0.58, 0.64, 1)
            Flat(marker, 1, 1, 1, 0.06)
            name:SetTextColor(DIM[1], DIM[2], DIM[3])
        end
    end

    row:SetScript("OnClick", function()
        set(not get())
        Paint()
    end)
    row.Paint = Paint
    Paint()
    return row
end

-- EllesmereUI version: text, whether it is not the tested one, and the
-- tested version.
local function VersionLine()
    local current, tested, matches = I.EUIVersion()
    if not current then return L["EllesmereUI version unknown"], true, tested end
    return "EllesmereUI " .. current, not matches, tested
end

local function BuildWelcome()
    local page = NewPage(PAGE_WELCOME)

    -- EllesmereUI version check.
    local badge = Disc(page, 18)
    badge:SetPoint("TOPLEFT", 0, page.top - 6)
    local tick = Tick(badge, 8, 0.05, 0.06, 0.08)
    local version = Label(page, 12, TEXT)
    version:SetPoint("LEFT", badge, "RIGHT", 10, 0)
    version:SetPoint("RIGHT", page, "RIGHT", 0, 0)

    refreshers[PAGE_WELCOME] = function()
        local text, warn, tested = VersionLine()
        SetShown(tick, not warn)
        if warn then
            badge.fill:SetVertexColor(WARN[1], WARN[2], WARN[3], 1)
            version:SetTextColor(WARN[1], WARN[2], WARN[3])
            version:SetText(text .. "  -  " .. string.format(L["tested with %s"], tested))
        else
            local _, _, _, rr, rg, rb = ns.ClassGradient()
            badge.fill:SetVertexColor(rr, rg, rb, 1)
            version:SetTextColor(DIM[1], DIM[2], DIM[3])
            version:SetText(text)
        end
    end
end

-- A radio choice: the same compact row as a switch, with a radio marker on
-- the left instead of a switch on the right.
local function RadioRow(page, y, title, description)
    local row = CreateFrame("Button", nil, page)
    row:SetPoint("TOPLEFT", 0, y)
    row:SetPoint("TOPRIGHT", 0, y)
    row:SetHeight(52)

    local bg = Solid(row, "BACKGROUND", 1, 1, 1, 0.035)
    bg:SetAllPoints()
    local hover = Solid(row, "HIGHLIGHT", 1, 1, 1, 0.03)
    hover:SetAllPoints()
    local marker = Solid(row, "ARTWORK", 1, 1, 1, 1)
    marker:SetPoint("TOPLEFT")
    marker:SetPoint("BOTTOMLEFT")
    marker:SetWidth(2)

    local ring = Disc(row, 16)
    ring:SetPoint("LEFT", 16, 0)
    local dot = Disc(ring, 6)
    dot:SetPoint("CENTER", 0, 0)
    dot.fill:SetVertexColor(0.05, 0.06, 0.08, 1)

    local name = Label(row, 14, TEXT)
    name:SetPoint("TOPLEFT", 44, -10)
    name:SetPoint("RIGHT", row, "RIGHT", -16, 0)
    name:SetText(title)

    local desc = Label(row, 11, DIM)
    desc:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4)
    desc:SetPoint("RIGHT", row, "RIGHT", -16, 0)
    desc:SetText(description)

    function row:SetSelected(selected)
        local _, _, _, rr, rg, rb = ns.ClassGradient()
        if selected then
            Gradient(marker)
            ring.fill:SetVertexColor(rr, rg, rb, 1)
            name:SetTextColor(TEXT[1], TEXT[2], TEXT[3])
        else
            Flat(marker, 1, 1, 1, 0.06)
            -- An opaque gray, not white at low alpha: see DISC_OFF.
            ring.fill:SetVertexColor(DISC_OFF[1], DISC_OFF[2], DISC_OFF[3], 1)
            name:SetTextColor(DIM[1], DIM[2], DIM[3])
        end
        dot:SetShown(selected)
    end
    return row
end

local function BuildProfile()
    local page = NewPage(PAGE_PROFILE)
    local choice = ns.db.profile

    local shared = RadioRow(
        page,
        page.top,
        string.format(L['Shared profile "%s"'], I.SHARED_PROFILE),
        L["One profile for every character you install on."]
    )
    local own = RadioRow(page, page.top - 58, L["New profile"], L["A name of your choice, for example per class."])

    -- Name field: directly under the "new profile" row, only while it is chosen.
    local field = CreateFrame("Frame", nil, page)
    field:SetPoint("TOPLEFT", own, "BOTTOMLEFT", 44, -8)
    field:SetSize(280, 30)
    local fieldBg = Solid(field, "BACKGROUND", 0, 0, 0, 0.35)
    fieldBg:SetAllPoints()
    local fieldBorder = Border(field)
    fieldBorder:Set(1, 1, 1, 0.12)

    local edit = CreateFrame("EditBox", nil, field)
    edit:SetPoint("TOPLEFT", 10, 0)
    edit:SetPoint("BOTTOMRIGHT", -10, 0)
    edit:SetAutoFocus(false)
    edit:SetMaxLetters(40)
    local fontPath, fontFlags = ns.GetFont()
    edit:SetFont(fontPath, 13, fontFlags)
    edit:SetTextColor(TEXT[1], TEXT[2], TEXT[3])
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnEditFocusGained", function() fieldBorder:SetGradient() end)
    edit:SetScript("OnEditFocusLost", function() fieldBorder:Set(1, 1, 1, 0.12) end)

    local note = L["EllesmereUI uses one active profile per account."]
    local noteLine = Label(page, 11, FAINT)
    noteLine:SetPoint("RIGHT", page, "RIGHT", 0, 0)
    noteLine:SetText(note)

    local function Paint()
        local isOwn = (choice.mode == "own")
        shared:SetSelected(not isOwn)
        own:SetSelected(isOwn)
        field:SetShown(isOwn)
        noteLine:ClearAllPoints()
        noteLine:SetPoint("TOPLEFT", own, "BOTTOMLEFT", 0, isOwn and -52 or -12)
        noteLine:SetPoint("RIGHT", page, "RIGHT", 0, 0)
        if isOwn and strtrim(edit:GetText() or "") == "" then
            edit:SetText(strtrim(choice.name or "") ~= "" and choice.name or I.SuggestedProfileName())
        end
        page:SetHint("")
    end

    edit:SetScript("OnTextChanged", function(self)
        choice.name = self:GetText() or ""
        page:SetHint("")
    end)
    shared:SetScript("OnClick", function()
        choice.mode = "shared"
        edit:ClearFocus()
        Paint()
    end)
    own:SetScript("OnClick", function()
        choice.mode = "own"
        Paint()
    end)

    refreshers[PAGE_PROFILE] = Paint
end

-- A theme card: a small mock unit frame and the theme's name.
local function ThemeCard(parent, key, title, description, width)
    local card = CreateFrame("Button", nil, parent)
    card:SetSize(width, 196)
    card.key = key

    local bg = Solid(card, "BACKGROUND", 1, 1, 1, 0.035)
    bg:SetAllPoints()
    local hover = Solid(card, "HIGHLIGHT", 1, 1, 1, 0.03)
    hover:SetAllPoints()
    card.border = Border(card)

    local stage = Solid(card, "BORDER", 0, 0, 0, 0.35)
    stage:SetPoint("TOPLEFT", 1, -1)
    stage:SetPoint("TOPRIGHT", -1, -1)
    stage:SetHeight(124)

    local barW = width - 56
    local back = Solid(card, "ARTWORK", 0.03, 0.03, 0.04, 1)
    back:SetSize(barW, 22)
    back:SetPoint("TOPLEFT", 28, -58)
    card.fill = Solid(card, "ARTWORK", 1, 1, 1, 1)
    card.fill:SetDrawLayer("ARTWORK", 1)
    card.fill:SetSize(barW * 0.82, 22)
    card.fill:SetPoint("TOPLEFT", back, "TOPLEFT", 0, 0)

    card.name = Label(card, 13, TEXT)
    card.name:SetPoint("BOTTOMLEFT", back, "TOPLEFT", 4, 6)
    card.name:SetText("Aritlok")

    local number = Label(card, 22, { 1, 1, 1 }, "RIGHT")
    number:SetPoint("BOTTOMRIGHT", back, "TOPRIGHT", -6, -8)
    number:SetText("82")

    card.power = Solid(card, "ARTWORK", 1, 1, 1, 1)
    card.power:SetSize(barW * 0.55, 3)
    card.power:SetPoint("TOPLEFT", back, "BOTTOMLEFT", 0, -8)

    local heading = Label(card, 15, TEXT)
    heading:SetPoint("TOPLEFT", 20, -138)
    heading:SetPoint("RIGHT", card, "RIGHT", -44, 0)
    heading:SetText(L[title])

    local desc = Label(card, 11, DIM)
    desc:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -5)
    desc:SetPoint("RIGHT", card, "RIGHT", -44, 0)
    desc:SetText(L[description])

    card.badge = Disc(card, 20)
    card.badge:SetPoint("BOTTOMRIGHT", -14, 14)
    Tick(card.badge, 9, 0.05, 0.06, 0.08)
    return card
end

local function BuildTheme()
    local page = NewPage(PAGE_THEME)
    local width = WIDTH - SIDEBAR - 2 * PAD
    local cardW = (width - 16) / 2

    local cards = {
        ThemeCard(page, "gradient", "Gradient", "Class colors, deep left to bright right.", cardW),
        ThemeCard(page, "dark", "Dark", "Flat dark bars, class-colored names.", cardW),
    }
    cards[1]:SetPoint("TOPLEFT", 0, page.top)
    cards[2]:SetPoint("TOPRIGHT", 0, page.top)

    local function Paint()
        local lr, lg, lb, rr, rg, rb = ns.ClassGradient()
        for i = 1, #cards do
            local card = cards[i]
            local selected = (ns.db.theme == card.key)
            card.fill:SetColorTexture(1, 1, 1, 1)
            if card.key == "gradient" then
                ns.HGradient(card.fill, lr, lg, lb, 1, rr, rg, rb, 1)
                card.name:SetTextColor(TEXT[1], TEXT[2], TEXT[3])
            else
                ns.HGradient(card.fill, 0.13, 0.14, 0.16, 1, 0.21, 0.22, 0.25, 1)
                card.name:SetTextColor(rr, rg, rb)
            end
            card.power:SetColorTexture(1, 1, 1, 1)
            ns.HGradient(card.power, 0.1, 0.35, 0.8, 1, 0.25, 0.7, 1, 1)

            if selected then
                card.border:SetGradient()
                card.badge.fill:SetVertexColor(rr, rg, rb, 1)
            else
                card.border:Set(1, 1, 1, 0.07)
            end
            card.badge:SetShown(selected)
            card:SetAlpha(selected and 1 or 0.72)
        end
    end

    for i = 1, #cards do
        cards[i]:SetScript("OnClick", function(self)
            ns.db.theme = self.key
            ns.RefreshShades()
            Paint()
        end)
    end
    refreshers[PAGE_THEME] = Paint
end

-- A page of switches for one group of installer options.
local function BuildOptions(index, group)
    local page = NewPage(index)
    local want = ns.db.install
    local rows = {}
    local y = page.top
    for i = 1, #I.options do
        local option = I.options[i]
        if option.group == group then
            rows[#rows + 1] = SwitchRow(
                page,
                y,
                option.title,
                option.desc,
                function() return want[option.key] end,
                function(v) want[option.key] = v end
            )
            y = y - 58
        end
    end
    refreshers[index] = function()
        for i = 1, #rows do
            rows[i].Paint()
        end
    end
end

-- Switches for what is hidden out of combat.
local function BuildCombat()
    local page = NewPage(PAGE_COMBAT)
    local want = ns.db.install.combat
    local rows = {}
    local y = page.top
    for i = 1, #I.combatOptions do
        local option = I.combatOptions[i]
        rows[#rows + 1] = SwitchRow(
            page,
            y,
            option.title,
            option.desc,
            function() return want[option.key] end,
            function(v) want[option.key] = v end
        )
        y = y - (option.desc and 58 or 46)
    end
    refreshers[PAGE_COMBAT] = function()
        for i = 1, #rows do
            rows[i].Paint()
        end
    end
end

-- Switches for the addon integrations whose addon is loaded.
local function BuildAddons()
    local page = NewPage(PAGE_ADDONS)
    local want = ns.db.install.addons
    local rows = {}

    local empty = Label(page, 13, DIM)
    empty:SetPoint("TOPLEFT", 0, page.top - 4)
    empty:SetPoint("RIGHT", page, "RIGHT", 0, 0)
    empty:SetText(L["No supported addon is loaded."])
    empty:Hide()

    refreshers[PAGE_ADDONS] = function()
        -- Built on first show: whether an addon is loaded is only known in game.
        if not page.built then
            page.built = true
            local found = I.DetectedAddons()
            local y = page.top
            for i = 1, #found do
                local entry = found[i]
                rows[#rows + 1] = SwitchRow(
                    page,
                    y,
                    entry.title,
                    entry.desc,
                    function() return want[entry.key] end,
                    function(v) want[entry.key] = v end
                )
                y = y - 58
            end
            empty:SetShown(#found == 0)
        end
        for i = 1, #rows do
            rows[i].Paint()
        end
    end
end

-- Number of options switched on in a group, as "3 of 5".
local function Count(group)
    local want = ns.db.install
    local on, total = 0, 0
    for i = 1, #I.options do
        local option = I.options[i]
        if option.group == group then
            total = total + 1
            if want[option.key] then on = on + 1 end
        end
    end
    return string.format(L["%d of %d"], on, total)
end

-- Number of things hidden out of combat, as "2 of 4".
local function CountCombat()
    local want = ns.db.install.combat
    local on = 0
    for i = 1, #I.combatOptions do
        if want[I.combatOptions[i].key] then on = on + 1 end
    end
    return string.format(L["%d of %d"], on, #I.combatOptions)
end

local function CountAddons()
    local want = ns.db.install.addons
    local found = I.DetectedAddons()
    if #found == 0 then return L["none"] end
    local on = 0
    for i = 1, #found do
        if want[found[i].key] then on = on + 1 end
    end
    return string.format(L["%d of %d"], on, #found)
end

local function BuildInstall()
    local page = NewPage(PAGE_INSTALL)

    -- Left column: what; right column: the choice. One line each.
    local keys = { "Profile", "Theme", "Layout", "Look", "Combat", "Addons", "EllesmereUI" }
    local values = {}
    local y = page.top
    for i = 1, #keys do
        local row = CreateFrame("Frame", nil, page)
        row:SetPoint("TOPLEFT", 0, y)
        row:SetPoint("TOPRIGHT", 0, y)
        row:SetHeight(36)
        local bg = Solid(row, "BACKGROUND", 1, 1, 1, (i % 2 == 1) and 0.035 or 0.015)
        bg:SetAllPoints()

        local key = Label(row, 12, DIM)
        key:SetPoint("LEFT", 16, 0)
        key:SetWidth(140)
        key:SetText(L[keys[i]])

        local value = Label(row, 13, TEXT)
        value:SetPoint("LEFT", 170, 0)
        value:SetPoint("RIGHT", row, "RIGHT", -16, 0)
        values[i] = value
        y = y - 38
    end

    refreshers[PAGE_INSTALL] = function()
        local db = ns.db
        values[1]:SetText(I.ProfileName())
        values[2]:SetText(L[db.theme == "dark" and "Dark" or "Gradient"])
        values[3]:SetText(Count("layout"))
        values[4]:SetText(Count("look"))
        values[5]:SetText(CountCombat())
        values[6]:SetText(CountAddons())
        local text, warn, tested = VersionLine()
        if warn then text = text .. "  -  " .. string.format(L["tested with %s"], tested) end
        values[7]:SetText(text)
        local c = warn and WARN or TEXT
        values[7]:SetTextColor(c[1], c[2], c[3])
        page:SetHint("")
    end
end

local function BuildDone()
    local page = NewPage(DONE)

    local badge = Disc(page, 56)
    badge:SetPoint("TOP", 0, -20)
    Tick(badge, 24, 0.05, 0.06, 0.08)

    local head = Label(page, 16, TEXT, "CENTER")
    head:SetPoint("TOP", badge, "BOTTOM", 0, -18)
    head:SetPoint("LEFT", page, "LEFT", 0, 0)
    head:SetPoint("RIGHT", page, "RIGHT", 0, 0)
    head:SetText(L["The settings are written. Press Reload UI to apply them."])

    -- Only what could not be applied is listed; the full list goes to chat.
    page.skipped = Label(page, 12, WARN, "CENTER", true)
    page.skipped:SetPoint("TOP", head, "BOTTOM", 0, -14)
    page.skipped:SetPoint("LEFT", page, "LEFT", 20, 0)
    page.skipped:SetPoint("RIGHT", page, "RIGHT", -20, 0)
    page.skipped:SetSpacing(4)
    page.skipped:SetMaxLines(4)

    refreshers[DONE] = function()
        local _, _, _, rr, rg, rb = ns.ClassGradient()
        badge.fill:SetVertexColor(rr, rg, rb, 1)
    end
end

-------------------------------------------------------------------------------
--  Navigation
-------------------------------------------------------------------------------
local function PaintSidebar(index)
    local _, _, _, rr, rg, rb = ns.ClassGradient()
    for i = 1, #stepItems do
        local item = stepItems[i]
        local done = (i < index)
        local current = (i == index)
        if done or current then
            item.disc.fill:SetVertexColor(rr, rg, rb, 1)
        else
            item.disc.fill:SetVertexColor(DISC_OFF[1], DISC_OFF[2], DISC_OFF[3], 1)
        end
        item.number:SetShown(not done)
        SetShown(item.tick, done)
        local numberColor = current and { 0.05, 0.06, 0.08 } or DIM
        item.number:SetTextColor(numberColor[1], numberColor[2], numberColor[3])
        local c = current and TEXT or (done and DIM or FAINT)
        item.label:SetTextColor(c[1], c[2], c[3])
        item.marker:SetShown(current)
        if item.link then
            if done then
                Flat(item.link, rr, rg, rb, 0.6)
            else
                Flat(item.link, 1, 1, 1, 0.08)
            end
        end
    end
end

local function Show(index)
    step = index
    if index <= #STEPS and index > reached then reached = index end
    for i = 1, DONE do
        local page = pages[i]
        if page then
            page:SetShown(i == index)
            if i == index then page.fade:Play() end
        end
    end

    local finished = (index == DONE)
    local _, _, _, rr, rg, rb = ns.ClassGradient()
    frame.kicker:SetTextColor(rr, rg, rb)
    if finished then
        frame.kicker:SetText("")
        frame.heading:SetText(L["Installed"])
    else
        frame.kicker:SetText(string.format("%d / %d", index, #STEPS))
        frame.heading:SetText(index == PAGE_WELCOME and "AritlokUI" or L[STEPS[index]])
    end

    PaintSidebar(finished and (#STEPS + 1) or index)

    -- Back is there on every page but the first, the closing page included.
    frame.back:SetShown(index > 1)
    frame.next:SetShown(not finished)
    frame.next:SetLabel(index == #STEPS and "Install" or "Continue")
    frame.reload:SetShown(finished)

    if refreshers[index] then refreshers[index]() end
end

-- Leaving the profile page forwards needs a usable profile name.
local function CanLeave()
    if step ~= PAGE_PROFILE then return true end
    local ok, reason = I.CheckProfileName(I.ProfileName())
    if not ok then pages[PAGE_PROFILE]:SetHint(reason, BAD) end
    return ok
end

local function RunInstall()
    local ok, result = ns.Install(ns.db.theme)
    if not ok then
        pages[PAGE_INSTALL]:SetHint(result or L["Unknown reason."], BAD)
        return
    end
    if #result.skipped > 0 then
        pages[DONE].skipped:SetText(string.format(L["Skipped: %s."], table.concat(result.skipped, "; ")))
    else
        pages[DONE].skipped:SetText("")
    end
    Show(DONE)
end

-------------------------------------------------------------------------------
--  Window
-------------------------------------------------------------------------------
local function BuildSidebar()
    local side = CreateFrame("Frame", nil, frame)
    side:SetPoint("TOPLEFT", 1, -1)
    side:SetPoint("BOTTOMLEFT", 1, 1)
    side:SetWidth(SIDEBAR)
    local bg = Solid(side, "BACKGROUND", 0.031, 0.034, 0.043, 1)
    bg:SetAllPoints()
    local edge = Solid(side, "BORDER", 1, 1, 1, 0.06)
    edge:SetPoint("TOPRIGHT")
    edge:SetPoint("BOTTOMRIGHT")
    edge:SetWidth(1)

    local logo = side:CreateTexture(nil, "ARTWORK")
    logo:SetSize(32, 32)
    logo:SetPoint("TOPLEFT", 24, -26)
    logo:SetTexture(ns.media.logo)

    local name = Label(side, 15, TEXT)
    name:SetPoint("LEFT", logo, "RIGHT", 12, 0)
    name:SetText("AritlokUI")

    local y = -92
    for i = 1, #STEPS do
        -- A button: a step already visited can be clicked to go back to it.
        local item = CreateFrame("Button", nil, side)
        item:SetPoint("TOPLEFT", 0, y)
        item:SetPoint("TOPRIGHT", 0, y)
        item:SetHeight(30)
        local hover = Solid(item, "HIGHLIGHT", 1, 1, 1, 0.04)
        hover:SetAllPoints()

        item.marker = Solid(item, "ARTWORK", 1, 1, 1, 1)
        item.marker:SetPoint("TOPLEFT")
        item.marker:SetPoint("BOTTOMLEFT")
        item.marker:SetWidth(2)
        local _, _, _, rr, rg, rb = ns.ClassGradient()
        item.marker:SetColorTexture(rr, rg, rb, 1)

        item.disc = Disc(item, 22)
        item.disc:SetPoint("LEFT", 24, 0)
        item.number = Label(item.disc, 11, DIM, "CENTER")
        item.number:SetPoint("CENTER", 0, 0)
        item.number:SetText(tostring(i))
        item.tick = Tick(item.disc, 9, 0.05, 0.06, 0.08)

        item.label = Label(item, 13, DIM)
        item.label:SetPoint("LEFT", item.disc, "RIGHT", 12, 0)
        item.label:SetPoint("RIGHT", item, "RIGHT", -12, 0)
        item.label:SetText(L[STEPS[i]])

        if i < #STEPS then
            item.link = Solid(side, "ARTWORK", 1, 1, 1, 0.08)
            item.link:SetWidth(1)
            item.link:SetPoint("TOP", item.disc, "BOTTOM", 0, -2)
            item.link:SetHeight(14)
        end

        item:SetScript("OnClick", function()
            if i == step or i > reached then return end
            -- Going forwards to a visited step still checks the profile name.
            if i > step and not CanLeave() then return end
            Show(i)
        end)

        stepItems[i] = item
        y = y - 44
    end

    local version = Label(side, 11, FAINT)
    version:SetPoint("BOTTOMLEFT", 24, 22)
    version:SetText(ns.VERSION)
end

local function Build()
    frame = CreateFrame("Frame", "AritlokUIInstaller", UIParent)
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetPoint("CENTER", 0, 30)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- Soft shadow, body, border.
    for i = 1, 3 do
        local shadow = Solid(frame, "BACKGROUND", 0, 0, 0, 0.14)
        shadow:SetPoint("TOPLEFT", -i * 3, i * 3)
        shadow:SetPoint("BOTTOMRIGHT", i * 3, -i * 3)
        shadow:SetDrawLayer("BACKGROUND", -8)
    end
    local bg = Solid(frame, "BACKGROUND", 0.043, 0.047, 0.058, 0.985)
    bg:SetAllPoints()
    Border(frame):Set(1, 1, 1, 0.09)

    -- Fade in when opened.
    local group = frame:CreateAnimationGroup()
    local fade = group:CreateAnimation("Alpha")
    fade:SetFromAlpha(0)
    fade:SetToAlpha(1)
    fade:SetDuration(0.2)
    fade:SetSmoothing("OUT")
    frame.fade = group

    BuildSidebar()

    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", SIDEBAR + 1, -1)
    content:SetPoint("BOTTOMRIGHT", -1, 1)
    frame.content = content

    -- Class gradient line across the top of the content area.
    local band = Solid(content, "ARTWORK", 1, 1, 1, 1)
    band:SetPoint("TOPLEFT")
    band:SetPoint("TOPRIGHT")
    band:SetHeight(2)
    Gradient(band)

    frame.kicker = Label(content, 11, DIM)
    frame.kicker:SetPoint("TOPLEFT", PAD, -28)
    frame.heading = Label(content, 24, TEXT)
    frame.heading:SetPoint("TOPLEFT", frame.kicker, "BOTTOMLEFT", 0, -6)
    frame.heading:SetPoint("RIGHT", content, "RIGHT", -56, 0)

    local close = CreateFrame("Button", nil, content)
    close:SetSize(28, 28)
    close:SetPoint("TOPRIGHT", -12, -12)
    local closeHover = Solid(close, "HIGHLIGHT", 1, 1, 1, 0.08)
    closeHover:SetAllPoints()
    Cross(close, 10, 0.75, 0.77, 0.82)
    close:SetScript("OnClick", function() frame:Hide() end)

    -- Footer
    local rule = Solid(content, "ARTWORK", 1, 1, 1, 0.06)
    rule:SetPoint("BOTTOMLEFT", PAD, FOOTER)
    rule:SetPoint("BOTTOMRIGHT", -PAD, FOOTER)
    rule:SetHeight(1)

    -- Back on the left, the way forward on the right.
    frame.back = Button(content, "Back", false, 96)
    frame.back:SetPoint("BOTTOMLEFT", PAD, 18)
    frame.back:SetScript("OnClick", function()
        if step == DONE then
            Show(PAGE_INSTALL)
        elseif step > 1 then
            Show(step - 1)
        end
    end)

    frame.next = Button(content, "Continue", true, 132)
    frame.next:SetPoint("BOTTOMRIGHT", -PAD, 18)
    frame.next:SetScript("OnClick", function()
        if not CanLeave() then return end
        if step < #STEPS then
            Show(step + 1)
        elseif step == #STEPS then
            RunInstall()
        end
    end)

    frame.reload = Button(content, "Reload UI", true, 160)
    frame.reload:SetPoint("BOTTOMRIGHT", -PAD, 18)
    -- The reload is the only thing this click does.
    frame.reload:SetScript("OnClick", function() ReloadUI() end)

    BuildWelcome()
    BuildProfile()
    BuildTheme()
    BuildOptions(PAGE_LAYOUT, "layout")
    BuildOptions(PAGE_LOOK, "look")
    BuildCombat()
    BuildAddons()
    BuildInstall()
    BuildDone()
end

function ns.OpenInstaller()
    if not ns.db then return end
    if not frame then Build() end
    ns.db.wizardSeen = true
    reached = 1
    Show(1)
    frame:Show()
    frame.fade:Play()
end

-------------------------------------------------------------------------------
--  First run
-------------------------------------------------------------------------------
-- EllesmereUI.RegisterExternalInstaller is deliberately NOT called: it keeps
-- EllesmereUI's own first-run pickers quiet until a profile import stamps
-- them done, and this installer copies a profile instead of importing one.
local offered = false
-- EllesmereUI's own first-run windows come first. On a fresh EllesmereUI
-- install it shows a module picker (which always ends in a reload) and, on
-- Forever, a style picker on the login after. While either is due this window
-- waits: it checks again every few seconds and opens once they are done,
-- which may be a login or two later. The installer also needs the profile
-- data EllesmereUI only writes after that first run.
--
-- RETEST after an EllesmereUI update (read from 9.8.4,
-- EllesmereUI_FirstInstall.lua and EllesmereUI_StyleChoicePopup.lua):
-- EllesmereUI._firstInstallPending (module picker due this session) and
-- EllesmereUIDB.styleChoicePending (style picker due).
local function EllesmereUIFirstRunDue()
    local eui = _G.EllesmereUI
    if type(eui) == "table" and eui._firstInstallPending then return true end
    local db = _G.EllesmereUIDB
    if type(db) ~= "table" or db.styleChoicePending then return true end
    return type(db.profiles) ~= "table" or next(db.profiles) == nil
end

ns.On("PLAYER_ENTERING_WORLD", function()
    if offered then return end
    offered = true
    local db = ns.db
    if not db or db.installed or db.wizardSeen then return end
    if not (C_Timer and C_Timer.After) then return end

    local tries = 0
    local function Try()
        if ns.db.installed or ns.db.wizardSeen then return end
        if EllesmereUIFirstRunDue() then
            -- Up to five minutes this session; after that, the next login.
            tries = tries + 1
            if tries < 100 then C_Timer.After(3, Try) end
            return
        end
        ns.RunOutOfCombat(ns.OpenInstaller)
    end
    C_Timer.After(3, Try)
end)
