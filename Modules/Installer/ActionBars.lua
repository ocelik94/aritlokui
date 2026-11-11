local addonName, ns = ...

-------------------------------------------------------------------------------
--  Installer step: action bars.
--  EllesmereUI draws a bar with no stored position at the screen center,
--  which is why every bar used here gets one.
-------------------------------------------------------------------------------

local I = ns.Installer
local Sub, Center, Hide = I.Sub, I.Center, I.Hide

local MAIN_BARS = { "MainBar", "Bar2", "Bar3", "Bar4", "Bar5", "Bar6", "Bar7", "Bar8" }

local function StyleBar(b, g)
    if g then
        b.buttonWidth = g.btnW -- square base size ...
        b.buttonHeight = g.btnW
        b.buttonShape = "cropped" -- ... drawn at 80% height, icon cropped not stretched
        b.buttonPadding = g.pad
    end
    b.borderEnabled = true
    b.borderSize = 1
    b.borderColor = { r = 0, g = 0, b = 0, a = 1 }
    b.borderClassColor = false
end

local function ShapeBar(b, rows)
    b.orientation = "horizontal"
    b.numIcons = 12
    b.overrideNumIcons = 12
    b.numRows = rows
    b.overrideNumRows = rows
end

local function Write(ctx, g)
    local ab = ctx.addons.EllesmereUIActionBars
    if type(ab) ~= "table" then return false end
    local bars = Sub(ab, "bars")
    local positions = Sub(ab, "barPositions")

    for i = 1, #MAIN_BARS do
        StyleBar(Sub(bars, MAIN_BARS[i]), g)
    end

    -- With the menu bar in place, the things it replaces go: Blizzard's micro
    -- menu and bag bar (through EllesmereUI's own visibility setting for them;
    -- their position belongs to Edit Mode and is never touched), and, when the
    -- long XP bar is on, the full-width XP and reputation bars.
    if ctx.menuBar then
        Hide(Sub(bars, "MicroBar"))
        Hide(Sub(bars, "BagBar"))
        if ctx.db.bar.showXP then
            ab.useBlizzardDataBars = false
            Hide(Sub(bars, "XPBar"))
            Hide(Sub(bars, "RepBar"))
        end
    end

    if not g then return true end

    -- Three rows at the bottom center. (ToxiUI uses ElvUI bars 1, 6 and 5,
    -- which are Blizzard's main, bottom-left and bottom-right bars: here
    -- bars 1, 2 and 3.)
    ShapeBar(Sub(bars, "MainBar"), 1)
    positions.MainBar = Center(0, g.row1)
    ShapeBar(Sub(bars, "Bar2"), 1)
    positions.Bar2 = Center(0, g.row1 - g.step)
    ShapeBar(Sub(bars, "Bar3"), 1)
    positions.Bar3 = Center(0, g.row1 - 2 * g.step)

    -- A 4 x 3 block on each side, as tall as the three rows. (Blizzard's two
    -- right-hand bars: here bars 4 and 5.)
    local blockW = 4 * g.btnW + 3 * g.pad
    local blockX = g.rowW / 2 + 4 * g.pad + blockW / 2
    local blockY = g.row1 - g.step
    ShapeBar(Sub(bars, "Bar4"), 3)
    positions.Bar4 = Center(-blockX, blockY)
    ShapeBar(Sub(bars, "Bar5"), 3)
    positions.Bar5 = Center(blockX, blockY)

    -- Stance bar above bar 1.
    positions.StanceBar = Center(0, g.row1 + g.btnH / 2 + g.pad + g.S(16))

    -- Bar 6: 2 across and 6 down, just right of the chat window, level with
    -- its bottom edge, shown only while the mouse is over it. These are the
    -- same fields EllesmereUI's own "mouseover" visibility mode sets.
    local side = Sub(bars, "Bar6")
    ShapeBar(side, 6) -- 12 buttons in 6 rows = 2 per row
    side.enabled = true
    side.barVisibility = "mouseover"
    side.alwaysHidden = false
    side.mouseoverEnabled = true
    side.mouseoverAlpha = 0
    side.combatHideEnabled = false
    side.combatShowEnabled = false
    local sideW = 2 * g.btnW + g.pad
    local sideH = 6 * g.btnH + 5 * g.pad
    positions.Bar6 = Center(g.chatX + g.chatW + g.S(14) + sideW / 2 - g.uiW / 2, g.chatY + sideH / 2 - g.uiH / 2)

    -- Pet bar: in the gap between that side bar and the left block of the
    -- main bars, as two rows of five, bottom-aligned with the main stack.
    -- Buttons are the main size where the gap allows and shrink to fit where
    -- it does not; on a screen too narrow for that it goes under the player
    -- cast bar instead (which hangs 10 under the frame and is 24 tall).
    local pet = Sub(bars, "PetBar")
    pet.buttonShape = "cropped"
    pet.orientation = "horizontal"
    local gapLeft = g.chatX + g.chatW + g.S(14) + sideW -- right edge of the side bar, from the screen's left
    local gapRight = g.uiW / 2 - blockX - blockW / 2 -- left edge of the bar 4 block
    local margin = g.S(10)
    local room = gapRight - gapLeft - 2 * margin
    local petW = math.min(g.btnW, math.floor((room - 4 * g.pad) / 5))
    if petW >= g.S(20) then
        pet.buttonWidth, pet.buttonHeight = petW, petW
        pet.buttonPadding = g.pad
        pet.numRows, pet.overrideNumRows = 2, 2
        local petH = 2 * petW * 0.8 + g.pad
        local stackBottom = g.row1 - 2 * g.step - g.btnH / 2
        positions.PetBar = Center((gapLeft + gapRight) / 2 - g.uiW / 2, stackBottom + petH / 2)
    else
        local narrow = (g.frameW - 9) / 10 -- ten across, as wide as the player frame
        pet.buttonWidth, pet.buttonHeight = narrow, narrow
        pet.buttonPadding = 1
        pet.numRows, pet.overrideNumRows = 1, 1
        local castbarBottom = g.frameY - g.frameH / 2 - g.S(10) - g.S(24)
        positions.PetBar = Center(-g.frameX, castbarBottom - g.S(6) - narrow * 0.8 / 2)
    end

    -- Bars 7-10 have no place in this layout. One that was never positioned
    -- would be drawn at the screen center, so it is switched off; one you have
    -- placed yourself is left alone. Re-enable them under /eui > Action Bars.
    local spare = { "Bar7", "Bar8", "Bar9", "Bar10" }
    for i = 1, #spare do
        if positions[spare[i]] == nil then
            local b = Sub(bars, spare[i])
            b.enabled = false
            Hide(b)
        end
    end
    return true
end

I.AddStep({
    order = 110,
    option = "actionBars",
    run = function(ctx)
        if Write(ctx, ctx:Geometry()) then
            ctx:Done("action bars")
        else
            ctx:Skip("action bars (module has no settings in this profile)")
        end
    end,
})
