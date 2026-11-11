local addonName, ns = ...

-------------------------------------------------------------------------------
--  Installer step: chat.
-------------------------------------------------------------------------------

local I = ns.Installer
local Sub = I.Sub

-- Chat: 520 x 200 in the bottom-left corner, clear of the menu bar (ToxiUI
-- keeps it 40 above; the gap also leaves room for the chat input line).
-- EllesmereUI stores the position of the chat text area; its panel adds a
-- button column on the left (about 40 wide), so the text area is inset by
-- that much to bring the panel itself into the corner. RETEST: the inset is
-- measured from a screenshot, not read from EllesmereUI.
local function Write(ctx, g)
    local mod = ctx.addons.EllesmereUIChat
    if type(mod) ~= "table" then return false end
    local chat = Sub(mod, "chat")
    chat.bgAlpha = 0.25 -- lighter panel, closer to bare text
    -- Messages use the global font at a small size.
    chat.font = "__global"
    chat.chatFontSize = 11
    -- Tabs keep EllesmereUI's proportional font and tighter side padding. A
    -- tab's width is set by Blizzard's chat dock, not by its label, so a wide
    -- monospaced label gets cut down to "Gen..."; the narrower font fits.
    chat.tabFont = "Expressway"
    chat.tabFontSize = 11
    chat.tabInnerPaddingX = 4
    chat.lockChatSize = true -- no accidental resizing
    if g then
        chat.chatPosition = { point = "BOTTOMLEFT", relPoint = "BOTTOMLEFT", x = g.chatX, y = g.chatY }
        chat.chatSize = { w = g.chatW, h = g.chatH } -- ToxiUI's is 450 wide; a little wider here
    end
    return true
end

-- Chat windows that float on their own (the Loot / Trade window) are docked
-- into the main chat window as tabs. This calls Blizzard's own docking
-- function once, from the installer click, out of combat; chat windows are
-- not protected frames, and the reload that follows the install starts clean.
-- RETEST on a new build. Returns how many were docked.
local function DockWindows()
    local dock = _G.GENERAL_CHAT_DOCK
    if type(FCF_DockFrame) ~= "function" or type(dock) ~= "table" or type(dock.DOCKED_CHAT_FRAMES) ~= "table" then return 0 end
    local count = 0
    for i = 3, (NUM_CHAT_WINDOWS or 10) do
        local frame = _G["ChatFrame" .. i]
        if type(frame) == "table" and frame.IsShown and frame:IsShown() and not frame.isDocked and not frame.isTemporary then
            FCF_DockFrame(frame, #dock.DOCKED_CHAT_FRAMES + 1, false)
            count = count + 1
        end
    end
    return count
end

I.AddStep({
    order = 120,
    option = "chat",
    run = function(ctx)
        if Write(ctx, ctx:Geometry()) then ctx:Done("chat") end
        local docked = DockWindows()
        if docked > 0 then ctx:Done("%d chat window(s) docked as tabs", docked) end
    end,
})
