local addonName, ns = ...

-------------------------------------------------------------------------------
--  Right-click on the menu bar's two profession buttons: the first opens
--  First Aid, the second Cooking (left-click still opens the profession
--  itself). EllesmereUI's DataBars has no setting for the right-click, so this
--  is the one place that reaches into frames EllesmereUI built:
--
--    * a post-hook on each button's OnClick (HookScript), which opens the
--      profession window the same way EllesmereUI's own left-click does
--      (C_TradeSkillUI.OpenTradeSkill with the skill line),
--    * a post-hook on its OnEnter that changes the tooltip's right-click line
--      from "Open Profession Book" to the profession it now opens, and
--    * the button's own right-click (a click on the profession micro button)
--      is switched off by clearing its "*type2" attribute, and put back when
--      the option is turned off.
--
--  The buttons are EllesmereUI's, not Blizzard's, but they are secure action
--  buttons, so attributes are only written outside combat. No snippet, no
--  state driver; nothing happens without the player's own click.
--
--  RETEST after an EllesmereUI update (read from 9.8.4,
--  EllesmereUIDataBars/Blocks/Profession.lua and Shared.lua): the buttons are
--  named "EllesmereUIDataBarsProf<n>_EDB<bar id>_<block id>", and a block of
--  type "profession" holds the two primary professions.
-------------------------------------------------------------------------------

local FIRST_AID, COOKING = 129, 185 -- skill lines
local SKILL = { FIRST_AID, COOKING } -- by button: first, second
local NAME = "EllesmereUIDataBarsProf%d_EDB%s_%s"

-- Buttons already hooked (EllesmereUI builds new ones when a bar is rebuilt),
-- and for each whether its right-click attribute was cleared here.
local hooked = setmetatable({}, { __mode = "k" })

local function Enabled()
    local db = ns.db
    return type(db) == "table" and db.bar.profRightClick and true or false
end

-- Opens the profession window, or closes it when it already shows that one.
local function Toggle(skillLine)
    if InCombatLockdown() then return end
    local ts = _G.C_TradeSkillUI
    if type(ts) ~= "table" or not ts.OpenTradeSkill then return end
    local info = ts.GetBaseProfessionInfo and ts.GetBaseProfessionInfo()
    local window = _G.ProfessionsFrame
    local open = type(info) == "table" and info.professionID == skillLine and window and window:IsShown()
    if open and ts.CloseTradeSkill then
        ts.CloseTradeSkill()
    else
        ts.OpenTradeSkill(skillLine)
    end
end

-- The profession's name in the client's language: from the character's own
-- professions when it has learned it, otherwise this addon's translation.
local FALLBACK = { [FIRST_AID] = "First Aid", [COOKING] = "Cooking" }
local function ProfessionName(skillLine)
    if GetProfessions and GetProfessionInfo then
        local list = { GetProfessions() }
        for i = 1, 6 do
            local index = list[i]
            if index then
                local name, _, _, _, _, _, id = GetProfessionInfo(index)
                if id == skillLine and type(name) == "string" and name ~= "" and not ns.IsSecret(name) then return name end
            end
        end
    end
    return ns.L[FALLBACK[skillLine]]
end

-- EllesmereUI's tooltip for these buttons still says right-click opens the
-- profession book. After it has drawn the tooltip (this runs after its
-- OnEnter), that one line is relabelled. The tooltip is EllesmereUI's named
-- frame; the line is found by its text, which EllesmereUI passes through its
-- own translation (EllesmereUI.L), so the same lookup gives the text to find.
local BOOK = "Open Profession Book"
local function Relabel(skillLine)
    local tip = _G.EllesmereUIDataBarsTip
    if type(tip) ~= "table" or not tip.GetRegions or not tip:IsShown() then return end
    local eui = _G.EllesmereUI
    local book = BOOK
    if type(eui) == "table" and type(eui.L) == "function" then book = eui.L(BOOK) or BOOK end
    local regions = { tip:GetRegions() }
    for i = 1, #regions do
        local region = regions[i]
        if region.GetObjectType and region:GetObjectType() == "FontString" then
            local text = region:GetText()
            if text ~= nil and not ns.IsSecret(text) and (text == book or text == BOOK) then
                region:SetText(string.format(ns.L["Open %s"], ProfessionName(skillLine)))
                return
            end
        end
    end
end

local function Prepare(button, skillLine, on)
    if not hooked[button] then
        hooked[button] = { cleared = false }
        button:HookScript("OnClick", function(_, mouseButton)
            if mouseButton == "RightButton" and Enabled() then Toggle(skillLine) end
        end)
        button:HookScript("OnEnter", function()
            if Enabled() then Relabel(skillLine) end
        end)
    end
    local state = hooked[button]
    if on and not state.cleared then
        if button:GetAttribute("*type2") == "click" then
            button:SetAttribute("*type2", nil)
            state.cleared = true
        end
    elseif not on and state.cleared then
        button:SetAttribute("*type2", "click")
        state.cleared = false
    end
end

local function Scan()
    local eui = _G.EllesmereUI
    local registry = type(eui) == "table" and eui._ModuleNS
    local mod = type(registry) == "table" and registry.EllesmereUIDataBars
    if type(mod) ~= "table" or type(mod.GetProfile) ~= "function" then return end
    local profile = mod.GetProfile()
    local bars = type(profile) == "table" and profile.bars
    if type(bars) ~= "table" then return end

    local on = Enabled()
    for i = 1, #bars do
        local bar = bars[i]
        local blocks = type(bar) == "table" and bar.blocks
        if type(blocks) == "table" then
            for j = 1, #blocks do
                local block = blocks[j]
                if type(block) == "table" and block.type == "profession" then
                    for n = 1, #SKILL do
                        local button = _G[string.format(NAME, n, tostring(bar.id), tostring(block.id))]
                        if type(button) == "table" and button.HookScript and button.SetAttribute then Prepare(button, SKILL[n], on) end
                    end
                end
            end
        end
    end
end

-- Attributes on secure buttons: outside combat only.
function ns.ApplyProfessionClicks() ns.RunOutOfCombat(Scan) end

ns.On("PLAYER_ENTERING_WORLD", function()
    ns.ApplyProfessionClicks()
    -- EllesmereUI may build its bars a moment after this event.
    if C_Timer and C_Timer.After then C_Timer.After(3, ns.ApplyProfessionClicks) end
end)
ns.On("SKILL_LINES_CHANGED", ns.ApplyProfessionClicks) -- a profession learned: its button appears
ns.On("PLAYER_REGEN_ENABLED", ns.ApplyProfessionClicks) -- bars rebuilt during a fight
