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
  "411", -- redefining a local (ok, reason = ... used twice in one function)
  "421", -- shadowing a local
  "423", -- shadowing a loop variable (nested "for i")
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
  "strtrim",

  -- Frames and constants
  "DEFAULT_CHAT_FRAME",
  "NUM_CHAT_WINDOWS",
  "STANDARD_TEXT_FONT",
  "UIParent",
  "Enum",

  -- Functions
  "CreateColor",
  "CreateFrame",
  "FCF_DockFrame",
  "GetBuildInfo",
  "GetLocale",
  "InCombatLockdown",
  "ReloadUI",
  "UnitClass",
  "UnitLevel",
  "UnitXP",
  "UnitXPMax",
  "issecretvalue",

  -- Namespaces
  "C_Timer",

  -- Libraries (embedded in EllesmereUI)
  "LibStub",
}
