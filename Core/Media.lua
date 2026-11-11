local addonName, ns = ...

-------------------------------------------------------------------------------
--  Media and colour helpers. Textures are this addon's own files; fonts are
--  whatever EllesmereUI is set to.
-------------------------------------------------------------------------------

local MEDIA = "Interface\\AddOns\\" .. addonName .. "\\Media\\"

ns.media = {
    flat = MEDIA .. "AritlokFlat", -- status bar fill: flat with a soft bottom shade
    fade = MEDIA .. "AritlokFade", -- transparent -> white, left to right
    dot = MEDIA .. "AritlokDot", -- soft round indicator
    icon = MEDIA .. "AritlokIcon",
    white = "Interface\\Buttons\\WHITE8x8",
}

-- Name the bar texture is registered under, and the key EllesmereUI stores for
-- a LibSharedMedia texture ("sm:" .. name).
ns.FLAT_NAME = "Aritlok Flat"
ns.FLAT_KEY = "sm:" .. ns.FLAT_NAME

-- EllesmereUI embeds LibSharedMedia-3.0 and lists every registered statusbar
-- texture in its texture dropdowns, so registering is all that is needed.
do
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM and LSM.Register then LSM:Register("statusbar", ns.FLAT_NAME, ns.media.flat) end
end

-- Monaspace Argon and Neon (GitHub Next), bundled unmodified under the SIL
-- Open Font License 1.1; the licence text sits next to the files. Registered
-- with LibSharedMedia so EllesmereUI lists every weight in its font dropdowns
-- and resolves them by name. The installer sets Neon Regular: the client has
-- no letter-spacing control, and at small sizes the heavier weights fill the
-- gaps between letters once the text shadow is added.
ns.FONT_NAME = "Monaspace Neon"
do
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM and LSM.Register then
        local fonts = MEDIA .. "Fonts\\"
        LSM:Register("font", "Monaspace Argon", fonts .. "MonaspaceArgon-Regular.otf")
        LSM:Register("font", "Monaspace Argon Light", fonts .. "MonaspaceArgon-Light.otf")
        LSM:Register("font", "Monaspace Argon Medium", fonts .. "MonaspaceArgon-Medium.otf")
        LSM:Register("font", "Monaspace Argon Bold", fonts .. "MonaspaceArgon-Bold.otf")
        LSM:Register("font", "Monaspace Neon", fonts .. "MonaspaceNeon-Regular.otf")
        LSM:Register("font", "Monaspace Neon Medium", fonts .. "MonaspaceNeon-Medium.otf")
        LSM:Register("font", "Monaspace Neon Bold", fonts .. "MonaspaceNeon-Bold.otf")
    end
end

ns.DEFAULT_ACCENT = { r = 0.094, g = 0.659, b = 1.0 }

-- Current EllesmereUI accent colour, or this addon's blue without it.
function ns.GetAccent()
    local eui = _G.EllesmereUI
    if type(eui) == "table" and eui.GetAccentColor then
        local r, g, b = eui.GetAccentColor()
        if type(r) == "number" and type(g) == "number" and type(b) == "number" then return r, g, b end
    end
    local a = ns.DEFAULT_ACCENT
    return a.r, a.g, a.b
end

-- The player's class colour. The class token is unit data, so it is checked
-- for secrecy before it is used as a table key.
function ns.GetPlayerClassColor()
    local _, token = UnitClass("player")
    if token ~= nil and not ns.IsSecret(token) then
        local colors = _G.CUSTOM_CLASS_COLORS or _G.RAID_CLASS_COLORS
        local c = colors and colors[token]
        if c then return c.r, c.g, c.b end
    end
    return ns.GetAccent()
end

function ns.Hex(r, g, b)
    return string.format("%02x%02x%02x", math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

-- Font path and flags from EllesmereUI's global font, with the client font as
-- the fallback. Called lazily (EllesmereUI's font cache needs its DB loaded).
function ns.GetFont()
    local eui = _G.EllesmereUI
    local path, flags
    if type(eui) == "table" then
        if eui.GetFontPath then path = eui.GetFontPath() end
        if eui.GetFontOutlineFlag then flags = eui.GetFontOutlineFlag() end
    end
    if type(path) ~= "string" or path == "" then path = STANDARD_TEXT_FONT end
    if type(flags) ~= "string" then flags = "" end
    return path, flags
end

-- Sets a font, falling back to the client font when the path is rejected.
function ns.SetFont(fontString, size)
    local path, flags = ns.GetFont()
    fontString:SetFont(path, size, flags)
    if not fontString:GetFont() then fontString:SetFont(STANDARD_TEXT_FONT, size, "") end
    if flags == "" then
        fontString:SetShadowColor(0, 0, 0, 0.9)
        fontString:SetShadowOffset(1, -1)
    end
end

-------------------------------------------------------------------------------
--  Gradients
--  A two-tone pair built from one colour: a deeper, slightly cooler left end
--  and a lighter right end. Only colour numbers go into the maths.
-------------------------------------------------------------------------------
function ns.GradientPair(r, g, b)
    local lr, lg, lb = r * 0.52, g * 0.52, b * 0.62
    local rr, rg, rb = r + (1 - r) * 0.28, g + (1 - g) * 0.28, b + (1 - b) * 0.28
    return lr, lg, lb, rr, rg, rb
end

-- The player's class colour as a gradient pair.
function ns.ClassGradient() return ns.GradientPair(ns.GetPlayerClassColor()) end

-- Paints a texture left -> right between two colours. The texture must be
-- white (SetColorTexture(1, 1, 1, 1) or a white file) for the colours to show.
function ns.HGradient(texture, r1, g1, b1, a1, r2, g2, b2, a2)
    if CreateColor and texture.SetGradient then
        texture:SetGradient("HORIZONTAL", CreateColor(r1, g1, b1, a1), CreateColor(r2, g2, b2, a2))
    else
        texture:SetVertexColor(r2, g2, b2, a2)
    end
end

-- Colours a string character by character between two colours. For this
-- addon's own text only (clock, titles, zone). A secret string, or one that
-- already carries escape codes, is returned untouched.
function ns.GradientText(text, r1, g1, b1, r2, g2, b2)
    if ns.IsSecret(text) or type(text) ~= "string" then return text end
    if text == "" or string.find(text, "|", 1, true) then return text end
    local chars = {}
    for ch in string.gmatch(text, "[%z\1-\127\194-\244][\128-\191]*") do
        chars[#chars + 1] = ch
    end
    local n = #chars
    if n == 0 then return text end
    for i = 1, n do
        local ch = chars[i]
        if ch ~= " " then
            local t = (n > 1) and ((i - 1) / (n - 1)) or 0
            chars[i] = "|cff" .. ns.Hex(r1 + (r2 - r1) * t, g1 + (g2 - g1) * t, b1 + (b2 - b1) * t) .. ch .. "|r"
        end
    end
    return table.concat(chars)
end
