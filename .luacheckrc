std = "lua51"
max_line_length = false
codes = true
self = false

exclude_files = {
  ".luacheckrc",
  ".release",
}

ignore = {
  "211", -- unused local variable (addonName at the top of every file, kept for the required first line)
  "212", -- unused argument (event handlers and widget callbacks take arguments they do not need)
  "213", -- unused loop variable
  "231", -- local variable never accessed
  "311", -- value assigned to a local is unused
  "431", -- shadowing an upvalue
  "432", -- shadowing an upvalue argument
  "542", -- empty if branch
}

-- Written by this addon.
globals = {
  "AritlokUIDB",
  "AritlokUI_OnAddonCompartmentClick",
  "SLASH_ARITLOKUI1",
  "SLASH_ARITLOKUI2",
  "SlashCmdList",
}

-- Read from the game client and EllesmereUI. Anything the addon reads through
-- _G.<name> (EllesmereUI, EllesmereUIDB, project constants) needs no entry.
read_globals = {
  "_G",

  -- Lua extensions the client adds
  "date",
  "strtrim",

  -- Frames and constants
  "DEFAULT_CHAT_FRAME",
  "GameTooltip",
  "NUM_BAG_SLOTS",
  "NUM_CHAT_WINDOWS",
  "STANDARD_TEXT_FONT",
  "UIParent",
  "Enum",

  -- Functions
  "BreakUpLargeNumbers",
  "CreateColor",
  "CreateFrame",
  "FCF_DockFrame",
  "GetBuildInfo",
  "GetCVar",
  "GetFramerate",
  "GetGameTime",
  "GetInventoryItemDurability",
  "GetMinimapZoneText",
  "GetMoney",
  "GetNetStats",
  "HasNewMail",
  "InCombatLockdown",
  "ReloadUI",
  "ToggleAllBags",
  "UnitClass",
  "UnitLevel",
  "UnitXP",
  "UnitXPMax",
  "issecretvalue",

  -- Namespaces
  "C_Container",
  "C_Timer",

  -- Libraries (embedded in EllesmereUI)
  "LibStub",
}
