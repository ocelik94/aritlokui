local addonName, ns = ...

-------------------------------------------------------------------------------
--  Installer step: the right edge of the screen, top to bottom:
--  minimap, quest tracker, tooltip, damage and healing meters.
--
--  Quest tracker, tooltip and meter spots were set by hand in unlock mode and
--  measured on a 2560 x 1440 screen; they are kept flush with the right edge
--  and scaled like the rest.
--    Quest tracker   301 x 398, top edge 346 below the top of the screen
--    Meters          394 x 241 on the menu bar, damage beside healing
--    Tooltip         its anchor box directly above the meters
-------------------------------------------------------------------------------

local I = ns.Installer
local Sub = I.Sub

I.AddStep({
    order = 130,
    option = "rightSide",
    run = function(ctx)
        local g = ctx:Geometry()
        if not g then return end
        local addons, S = ctx.addons, g.S

        -- Minimap: top-right corner, 4 in from each edge (ToxiUI's MinimapMover).
        local mm = addons.EllesmereUIMinimap
        if type(mm) == "table" then
            local inset = S(4)
            local minimap = Sub(mm, "minimap")
            minimap.position = { point = "TOPRIGHT", relPoint = "TOPRIGHT", x = -inset, y = -inset }
            -- EllesmereUI's own minimap button stands on the button row,
            -- outside the addon-button group. The value is its place in the row.
            local ungrouped = Sub(minimap, "ungroupedButtons")
            if not ungrouped.EllesmereUIMinimapButton then ungrouped.EllesmereUIMinimapButton = 1 end
            ctx:Done("minimap")
        end

        -- Quest tracker (EllesmereUI's custom tracker): a point, a width and a
        -- maximum height.
        local qt = addons.EllesmereUIQuestTracker
        if type(qt) == "table" then
            local t = Sub(qt, "questTracker")
            t.customPos = { point = "TOPRIGHT", relPoint = "TOPRIGHT", x = 0, y = -S(346) }
            t.customWidth = S(301)
            t.customMaxHeight = S(398)
            ctx:Done("quest tracker")
        end

        local dmW, dmH = S(394), S(241)
        local dmBottom = g.reserved + 3
        local dm = addons.EllesmereUIDamageMeters
        if type(dm) == "table" then
            -- Two windows sharing that area side by side: damage done (which
            -- also shows per-second) on the left, healing done on the right.
            -- A window is stored as its top-left corner measured from the
            -- bottom-left corner of the screen.
            local types = Enum and Enum.DamageMeterType
            local damageType = (types and types.DamageDone) or 0
            local healingType = (types and types.HealingDone) or 2
            local gap = 2
            local leftW = math.floor((dmW - gap) / 2)
            local rightW = dmW - gap - leftW
            local look = Sub(dm, "dm")
            local windows = Sub(look, "windows")
            look.windowCount = 2

            local damage = Sub(windows, 1)
            damage.width, damage.height = leftW, dmH
            damage.position = { x = g.uiW - dmW, y = dmBottom + dmH }
            damage.curDMType = damageType
            damage.locked = true -- no accidental dragging or closing

            local healing = Sub(windows, 2)
            healing.width, healing.height = rightW, dmH
            healing.position = { x = g.uiW - rightW, y = dmBottom + dmH }
            healing.curDMType = healingType
            healing.locked = true

            -- Look: no black window or header box, just the bars over the
            -- game world, with our flat bar texture and the header buttons
            -- shown only on mouse-over. EllesmereUI keeps a second copy of
            -- some of these per style ("eui" is the flat one), so both are set.
            look.bgAlpha = 0
            look.hdrBgAlpha = 0
            look.hdrMouseoverIcons = true
            look.barBgAlpha = 0.35
            look.barTexture = ns.FLAT_KEY
            local slot = type(look._styleSlots) == "table" and look._styleSlots.eui
            if type(slot) == "table" then
                slot.bgAlpha = 0
                slot.barBgAlpha = 0.35
                slot.barTexture = ns.FLAT_KEY
            end
            ctx:Done("damage and healing meters")
        end

        -- Tooltip fixed position: stored on the profile itself, as the center
        -- of its anchor box offset from the screen center. The box is
        -- EllesmereUI's fixed 280 x 165, not scaled.
        local boxW, boxH = 280, 165
        ctx.profile.tooltipFixedPos = {
            centerX = g.uiW / 2 - boxW / 2,
            centerY = -g.uiH / 2 + dmBottom + dmH + S(4) + boxH / 2, -- directly above the meters
        }
        ctx:Done("tooltip")
    end,
})
