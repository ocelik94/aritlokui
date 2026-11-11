local addonName, ns = ...

-------------------------------------------------------------------------------
--  Localization
--  ns.L["English text"] gives the text in the client's language. The English
--  text is the key, so a string with no translation simply shows in English.
--  Translations live in Locales/<locale>.lua; each of those files returns at
--  once on any other client language.
--
--  Text with changing parts uses string.format placeholders (%s, %d) so a
--  translation can reorder the sentence around them.
-------------------------------------------------------------------------------

ns.locale = (GetLocale and GetLocale()) or "enUS"

ns.L = setmetatable({}, {
    __index = function(_, key) return key end,
})
