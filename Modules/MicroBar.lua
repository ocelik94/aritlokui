local addonName, ns = ...

-------------------------------------------------------------------------------
--  Menu buttons
--  A row of small flat buttons at the left end of the info bar: character,
--  spellbook, talents, quests, social, guild, group finder, map, game menu
--  and bags.
--
--  Opening a Blizzard panel from addon code is what produces "Interface
--  action failed because of an AddOn". So these buttons open nothing
--  themselves: each one is this addon's own SecureActionButtonTemplate button
--  whose click is forwarded, by the client, to the matching Blizzard micro
--  button (type "click"). No secure snippet is compiled and no attribute is
--  written onto a Blizzard frame. A micro button this client does not have is
--  simply left out.
--
--  The buttons are protected frames, and so is the holder they sit in. They
--  are created, shown, hidden and moved only outside combat; every such step
--  goes through ns.RunOutOfCombat and waits for PLAYER_REGEN_ENABLED.
--  RETEST on a new build: the micro button names below and the click
--  forwarding itself.
-------------------------------------------------------------------------------

local SIZE, SPACING, LEFT_PAD = 22, 4, 12

-- First existing global name wins.
local ENTRIES = {
    { letter = "C", tip = "Character", names = { "CharacterMicroButton" } },
    { letter = "S", tip = "Spellbook", names = { "SpellbookMicroButton", "PlayerSpellsMicroButton" } },
    { letter = "T", tip = "Talents", names = { "TalentMicroButton" } },
    { letter = "Q", tip = "Quest Log", names = { "QuestLogMicroButton" } },
    { letter = "F", tip = "Social", names = { "SocialsMicroButton" } },
    { letter = "G", tip = "Guild", names = { "GuildMicroButton" } },
    { letter = "L", tip = "Group Finder", names = { "LFGMicroButton", "LFDMicroButton" } },
    { letter = "M", tip = "World Map", names = { "WorldMapMicroButton" } },
    { letter = "=", tip = "Game Menu", names = { "MainMenuMicroButton" } },
}

local holder
local buttons = {}
local built = false

local function FindButton(names)
    for i = 1, #names do
        local f = _G[names[i]]
        if type(f) == "table" and f.Click then return f end
    end
    return nil
end

local function Decorate(button, letter, tip)
    button:SetSize(SIZE, SIZE)

    local hover = button:CreateTexture(nil, "BACKGROUND")
    hover:SetAllPoints()
    hover:SetColorTexture(1, 1, 1, 0.1)
    hover:Hide()

    local label = button:CreateFontString(nil, "OVERLAY")
    ns.SetFont(label, 13)
    label:SetPoint("CENTER", 0, 0)
    label:SetText(letter)
    button.label = label

    button:SetScript("OnEnter", function(self)
        hover:Show()
        local _, _, _, rr, rg, rb = ns.ClassGradient()
        label:SetTextColor(rr, rg, rb)
        if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(tip)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function()
        hover:Hide()
        label:SetTextColor(0.85, 0.86, 0.9)
        if GameTooltip then GameTooltip:Hide() end
    end)
    label:SetTextColor(0.85, 0.86, 0.9)
end

-- Out of combat only (called through ns.RunOutOfCombat).
local function Build()
    if built then return end
    built = true

    holder = CreateFrame("Frame", "AritlokUIMicroBar", UIParent)
    holder:SetFrameStrata("MEDIUM")
    holder:SetHeight(SIZE)

    for i = 1, #ENTRIES do
        local entry = ENTRIES[i]
        local target = FindButton(entry.names)
        if target then
            local button = CreateFrame("Button", "AritlokUIMicroButton" .. i, holder, "SecureActionButtonTemplate")
            button:RegisterForClicks("AnyUp")
            button:SetAttribute("useOnKeyDown", false)
            button:SetAttribute("*type1", "click")
            button:SetAttribute("*clickbutton1", target)
            Decorate(button, entry.letter, entry.tip)
            buttons[#buttons + 1] = button
        end
    end

    -- Bags are not a protected panel; a plain button is enough.
    if ToggleAllBags then
        local bags = CreateFrame("Button", "AritlokUIMicroButtonBags", holder)
        Decorate(bags, "B", "Bags")
        bags:SetScript("OnClick", function() ToggleAllBags() end)
        buttons[#buttons + 1] = bags
    end

    for i = 1, #buttons do
        buttons[i]:ClearAllPoints()
        buttons[i]:SetPoint("LEFT", holder, "LEFT", (i - 1) * (SIZE + SPACING), 0)
    end
    holder:SetWidth(math.max(1, #buttons * (SIZE + SPACING) - SPACING))
end

local function Wanted()
    local cfg = ns.db and ns.db.bar
    return cfg and cfg.enabled and cfg.micro and cfg.mode ~= "eui"
end

-- Width the info bar keeps free on its left for the buttons. Counted from the
-- entry list, so it is known before the buttons exist.
function ns.MicroBarWidth()
    if not Wanted() then return 0 end
    local n = built and #buttons or (#ENTRIES + 1)
    return LEFT_PAD + n * (SIZE + SPACING)
end

local function Layout()
    if not Wanted() then
        if holder then holder:Hide() end
        return
    end
    Build()
    local height = ns.InfoBarHeight()
    local inset = (height - SIZE) / 2
    holder:ClearAllPoints()
    if ns.db.bar.position == "TOP" then
        holder:SetPoint("TOPLEFT", UIParent, "TOPLEFT", LEFT_PAD, -inset)
    else
        holder:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", LEFT_PAD, inset)
    end
    holder:Show()
end

-- Safe to call at any time: in combat the layout waits in the combat queue.
function ns.ApplyMicroBar() ns.RunOutOfCombat(Layout) end
