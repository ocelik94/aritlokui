local addonName, ns = ...

-------------------------------------------------------------------------------
--  Release notes, shown on the Changelog page of the settings (Options.lua).
--  The client cannot read CHANGELOG.md, so the same notes are kept here:
--  newest first, one entry per release, and a new release adds to both files.
--  The text is English only, like CHANGELOG.md itself.
-------------------------------------------------------------------------------

ns.changelog = {
    {
        version = "0.5.0",
        items = {
            "One background color for every window: bags, the Blizzard windows EllesmereUI skins (switched to its flat "
                .. 'Modern style), tooltips and the RestedXP guide. New "One window color" switch on the Look page; the window '
                .. "and tooltip part applies to every EllesmereUI profile.",
        },
        note = "Run /aui install again to apply it.",
    },
    {
        version = "0.4.0",
        items = {
            "Cast bars no longer draw over windows such as the bags.",
            'Bags open as one bag by default (part of the "Compact bags" switch).',
            "Right-click the first profession on the menu bar to open First Aid, the second to open Cooking; left-click still "
                .. "opens the profession itself. Can be switched off under Menu Bar in the settings.",
        },
        note = "Run /aui install again to apply the cast bar and bag changes.",
    },
    {
        version = "0.3.0",
        items = {
            'RestedXP Guides: a new "AritlokUI" theme for its guide window, arrow, map pins and tooltips, in your accent color '
                .. "and interface font. The installer selects it when RestedXP is loaded; it can also be picked in RestedXP's own "
                .. "theme list.",
            "The installer's Addons page is a plain list with one switch per addon; Questie's two switches are now one.",
            'The name is written "AritlokUI" everywhere, including the addon list.',
            "The settings show AritlokUI's pages under General, next to this new Changelog page.",
        },
        note = "Run /aui install again to apply the RestedXP theme.",
    },
    {
        version = "0.2.0",
        items = {
            "The pet frame's health bar now uses your class color, a shade darker than the player frame, instead of green.",
            "EllesmereUI's minimap button is placed on the button row, outside the addon-button group.",
            'Bags open in EllesmereUI\'s compact view (new "Compact bags" switch on the Look page).',
        },
        note = "Run /aui install again to apply these.",
    },
    {
        version = "0.1.1",
        items = {
            "Smaller name text on the player and target frames, so a long name no longer runs into the health percentage.",
        },
        note = "Run /aui install again to apply it.",
    },
    {
        version = "0.1.0",
        items = {
            "First release.",
            "Installer (/aui install): a few short pages with a clickable step sidebar, theme previews and switches; themes a "
                .. "copy of your EllesmereUI profile and warns when your EllesmereUI version is not the tested one.",
            "Install into the shared AritlokUI profile or one with a name you choose.",
            "Questie: its quest tracker can take the place of EllesmereUI's, in the same font and spot.",
            "Choose what hides out of combat: action bars, pet bar, unit frames, meters.",
            "Gradient and Dark themes for EllesmereUI's unit frame bars.",
            "ToxiUI-style layout: unit frames either side of a free center, action bars at the bottom, cooldown manager rows "
                .. "under the power bar, cast bars under their frames.",
            "Menu bar built on EllesmereUI DataBars, with a fading backdrop and a longer experience bar.",
            "Chat in the bottom-left corner; minimap, quest tracker, tooltip and damage / healing meters on the right edge.",
            "Pixel-perfect UI scale.",
            "Monaspace Neon font (Argon bundled as an alternative).",
            "English, German and French localization.",
        },
    },
}
