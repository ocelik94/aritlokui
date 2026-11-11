local addonName, ns = ...

-------------------------------------------------------------------------------
--  Installer step: what is hidden out of combat.
--  A hidden element still shows in combat, and whenever the mouse is over it.
--
--  That is EllesmereUI's own visibility setting for the element: the modes
--  "in combat" and "mouse-over" together, matched as "any". It is written
--  through EllesmereUI.SetVisibilitySelection, which stores the mode set and
--  the single legacy value older readers use. EllesmereUI does the showing
--  and hiding (its action bars and unit frames are protected frames, which it
--  handles with its own secure drivers); nothing here touches a frame.
-------------------------------------------------------------------------------

local I = ns.Installer
local Sub = I.Sub

-- `key` is the field in AritlokUIDB.install.combat: true = hidden out of
-- combat (until a fight or the mouse brings it back). Titles and descriptions
-- are English here and translated where shown.
I.combatOptions = {
    { key = "actionBars", title = "Action bars", desc = "Bars 1 to 5 and the stance bar. The mouse-over bar stays as it is." },
    { key = "petBar", title = "Pet bar" },
    { key = "unitFrames", title = "Unit frames", desc = "Player, target, pet, target of target and focus." },
    { key = "meters", title = "Damage and healing meters" },
}

-- Sets one element's visibility: hidden out of combat (shown in combat or on
-- mouse-over), or always shown. `legacyKey` is the element's single-value
-- setting; `applyScalar`, when given, writes that value plus whatever else
-- the module keeps in step with it.
local function SetVisibility(eui, store, legacyKey, hide, applyScalar)
    local selection = hide and { in_combat = true, mouseover = true } or {}
    if eui.SetVisibilitySelection then
        eui.SetVisibilitySelection(store, legacyKey, selection, applyScalar)
    else
        -- Same result by hand, should the setter be missing.
        local scalar = hide and "mouseover" or "always"
        if applyScalar then
            applyScalar(store, scalar)
        else
            store[legacyKey] = scalar
        end
        store.visibilityModes = hide and selection or nil
    end
    -- "any": being in combat is enough to show it; mouse-over is the other way in.
    store.visibilityMatch = hide and "any" or nil
end

-- An action bar keeps a few more fields in step with its visibility value:
-- the ones EllesmereUI's own action bar code sets for each mode.
local function ApplyBarScalar(bar, scalar)
    local mouseover = (scalar == "mouseover")
    bar.barVisibility = scalar
    bar.alwaysHidden = (scalar == "never")
    bar.combatHideEnabled = (scalar == "out_of_combat")
    bar.combatShowEnabled = (scalar == "in_combat")
    if mouseover then
        if not bar._savedBarAlpha then bar._savedBarAlpha = bar.mouseoverAlpha or 1 end
        bar.mouseoverAlpha = 0
    elseif bar.mouseoverEnabled and bar._savedBarAlpha then
        bar.mouseoverAlpha = bar._savedBarAlpha
        bar._savedBarAlpha = nil
    end
    bar.mouseoverEnabled = mouseover
end

-- After every layout step, so it has the last word on these settings.
I.AddStep({
    order = 150,
    option = nil,
    run = function(ctx)
        local want = ctx.want.combat
        if type(want) ~= "table" then return end
        local eui, addons = ctx.eui, ctx.addons

        local ab = addons.EllesmereUIActionBars
        if type(ab) == "table" then
            local bars = Sub(ab, "bars")
            local main = { "MainBar", "Bar2", "Bar3", "Bar4", "Bar5", "StanceBar" }
            for i = 1, #main do
                SetVisibility(eui, Sub(bars, main[i]), "barVisibility", want.actionBars, ApplyBarScalar)
            end
            SetVisibility(eui, Sub(bars, "PetBar"), "barVisibility", want.petBar, ApplyBarScalar)
        end

        local uf = addons.EllesmereUIUnitFrames
        if type(uf) == "table" then
            local units = { "player", "target", "pet", "targettarget", "focus" }
            for i = 1, #units do
                SetVisibility(eui, Sub(uf, units[i]), "barVisibility", want.unitFrames)
            end
        end

        local dm = addons.EllesmereUIDamageMeters
        if type(dm) == "table" then SetVisibility(eui, Sub(dm, "dm"), "visibility", want.meters) end

        ctx:Done("combat visibility")
    end,
})
