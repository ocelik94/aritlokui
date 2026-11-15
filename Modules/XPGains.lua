local addonName, ns = ...

-------------------------------------------------------------------------------
--  Experience per kill and per quest, for the XP bar's tooltip: the last ten
--  of each are kept per character, and their average says how many more
--  kills or quests the level takes.
--
--  No combat log. A gain is the change in UnitXP at PLAYER_XP_UPDATE. What it
--  came from is told by the events around it:
--    * QUEST_TURNED_IN close to it: a quest,
--    * otherwise CHAT_MSG_COMBAT_XP_GAIN close to it: a kill (the message
--      itself is never read, only that it came),
--    * neither (exploration and the like): not counted.
--  The order of these events is not fixed, so a gain is sorted a moment
--  after it happened, once all of them have arrived.
--
--  RETEST on a new client build: QUEST_TURNED_IN and CHAT_MSG_COMBAT_XP_GAIN
--  must exist (ns.missingEvents, /aui probe). Kill experience includes the
--  rested bonus, so the average drops once rested experience runs out.
-------------------------------------------------------------------------------

local KEEP = 10 -- gains averaged, per kind
local WINDOW = 1 -- seconds between a gain and the event that explains it
local SORT_DELAY = 0.5

local lastXP, lastMax
local killAt, questAt = -100, -100
local session = { kill = {}, quest = {} } -- when the character's GUID is unknown

local function Num(v)
    if type(v) == "number" and not ns.IsSecret(v) then return v end
    return nil
end

-- This character's lists, kept in AritlokUIDB.xpGains under its GUID.
local function Lists()
    local db = ns.db
    local guid = UnitGUID and UnitGUID("player")
    if type(db) ~= "table" or type(guid) ~= "string" or ns.IsSecret(guid) then return session end
    if type(db.xpGains) ~= "table" then db.xpGains = {} end
    local lists = db.xpGains[guid]
    if type(lists) ~= "table" then
        lists = {}
        db.xpGains[guid] = lists
    end
    if type(lists.kill) ~= "table" then lists.kill = {} end
    if type(lists.quest) ~= "table" then lists.quest = {} end
    return lists
end

local function Add(kind, amount)
    local list = Lists()[kind]
    list[#list + 1] = amount
    while #list > KEEP do
        table.remove(list, 1)
    end
end

-- The average gain of one kind and how many it is taken from; nil when none
-- are known yet.
function ns.XPAverage(kind)
    local list = Lists()[kind]
    if type(list) ~= "table" or #list == 0 then return nil end
    local sum = 0
    for i = 1, #list do
        sum = sum + list[i]
    end
    return sum / #list, #list
end

local function Snapshot()
    lastXP, lastMax = Num(UnitXP and UnitXP("player")), Num(UnitXPMax and UnitXPMax("player"))
end

local function Sort(gain, at)
    if math.abs(questAt - at) <= WINDOW then
        Add("quest", gain)
    elseif math.abs(killAt - at) <= WINDOW then
        Add("kill", gain)
    end
end

ns.On("PLAYER_ENTERING_WORLD", Snapshot)

ns.On("PLAYER_XP_UPDATE", function(unit)
    if unit ~= nil and unit ~= "player" then return end
    local xp = Num(UnitXP and UnitXP("player"))
    local beforeXP, beforeMax = lastXP, lastMax
    Snapshot()
    if not (xp and beforeXP and beforeMax) then return end
    local gain = xp - beforeXP
    -- A level-up: the rest of the old level, then into the new one.
    if gain < 0 then gain = beforeMax - beforeXP + xp end
    if gain <= 0 then return end
    local at = GetTime()
    if C_Timer and C_Timer.After then
        C_Timer.After(SORT_DELAY, function() Sort(gain, at) end)
    else
        Sort(gain, at)
    end
end)

ns.On("QUEST_TURNED_IN", function() questAt = GetTime() end)
ns.On("CHAT_MSG_COMBAT_XP_GAIN", function() killAt = GetTime() end)
