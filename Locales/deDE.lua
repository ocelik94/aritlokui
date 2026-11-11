local addonName, ns = ...

-------------------------------------------------------------------------------
--  German
--  One line per English text. Placeholders (%s, %d, %.4f, %%) must stay in
--  the same order as in the English key.
-------------------------------------------------------------------------------

if ns.locale ~= "deDE" then return end

local L = ns.L

L["written for interface %s, this client reports %s. Run /aui probe and retest."] =
    "geschrieben für Interface %s, dieser Client meldet %s. Führe /aui probe aus und teste erneut."
L["%d%% to level %d"] = "%d%% bis Stufe %d"
L["action bars"] = "Aktionsleisten"
L["action bars (module has no settings in this profile)"] = "Aktionsleisten (Modul hat in diesem Profil keine Einstellungen)"
L["Questie tracker look"] = "Aussehen der Questie-Questverfolgung"
L["Questie quest tracker in place of EllesmereUI's"] = "Questie-Questverfolgung anstelle der von EllesmereUI"
L["Questie tracker style"] = "Stil der Questie-Questverfolgung"
L["Interface font, no backdrop."] = "Interface-Schrift, kein Hintergrund."
L["Use Questie's quest tracker"] = "Questverfolgung von Questie verwenden"
L["Replaces EllesmereUI's tracker."] = "Ersetzt die Questverfolgung von EllesmereUI."
L["chat"] = "Chat"
L["%d chat window(s) docked as tabs"] = "%d Chatfenster als Reiter angedockt"
L["combat visibility"] = "Sichtbarkeit im Kampf"
L["Action bars"] = "Aktionsleisten"
L["Bars 1 to 5 and the stance bar. The mouse-over bar stays as it is."] =
    "Leisten 1 bis 5 und die Haltungsleiste. Die Mouseover-Leiste bleibt, wie sie ist."
L["Pet bar"] = "Begleiterleiste"
L["Unit frames"] = "Einheitenfenster"
L["Player, target, pet, target of target and focus."] = "Spieler, Ziel, Begleiter, Ziel des Ziels und Fokus."
L["Damage and healing meters"] = "Schadens- und Heilungsanzeige"
L["Enter a profile name."] = "Gib einen Profilnamen ein."
L["The profile name is too long (40 characters at most)."] = "Der Profilname ist zu lang (höchstens 40 Zeichen)."
L['A profile named "%s" already exists and was not made by Aritlok UI. Pick another name.'] =
    'Ein Profil namens "%s" existiert bereits und wurde nicht von Aritlok UI erstellt. Wähle einen anderen Namen.'
L["EllesmereUI is not loaded."] = "EllesmereUI ist nicht geladen."
L["EllesmereUI has no profile data yet. Log in once with it enabled, then try again."] =
    "EllesmereUI hat noch keine Profildaten. Logge dich einmal mit aktiviertem EllesmereUI ein und versuche es erneut."
L["This EllesmereUI version has no %s(). Run /aui probe."] = "Diese EllesmereUI-Version hat kein %s(). Führe /aui probe aus."
L["You are in combat. Try again after the fight."] = "Du bist im Kampf. Versuche es nach dem Kampf erneut."
L["cannot install: %s"] = "Installation nicht möglich: %s"
L["EllesmereUI did not switch to the %s profile. Nothing was changed."] =
    "EllesmereUI hat nicht zum Profil %s gewechselt. Es wurde nichts geändert."
L["EllesmereUI returned no profile data. Nothing was changed."] = "EllesmereUI hat keine Profildaten geliefert. Es wurde nichts geändert."
L["note: written for EllesmereUI %s, you have %s. Some settings may not apply."] =
    "Hinweis: geschrieben für EllesmereUI %s, du hast %s. Manche Einstellungen greifen eventuell nicht."
L["an unknown version"] = "eine unbekannte Version"
L['installed the %s theme into EllesmereUI profile "%s": %s.'] = 'Thema %s im EllesmereUI-Profil "%s" installiert: %s.'
L["nothing"] = "nichts"
L["skipped: %s."] = "übersprungen: %s."
L["Dark"] = "Dunkel"
L["Gradient"] = "Farbverlauf"
L["Player, target and cooldown rows."] = "Spieler, Ziel und Abklingzeit-Reihen."
L["Bottom rows, side blocks, mouse-over bar."] = "Reihen unten, Seitenblöcke, Mouseover-Leiste."
L["Menu bar"] = "Menüleiste"
L["Needs EllesmereUI DataBars."] = "Benötigt EllesmereUI DataBars."
L["Chat"] = "Chat"
L["Bottom left, smaller text."] = "Unten links, kleinere Schrift."
L["Right edge"] = "Rechter Rand"
L["Minimap, quests, tooltip, meters."] = "Minikarte, Quests, Tooltip, Anzeigen."
L["Flat style"] = "Flacher Stil"
L["Replaces the bronze WoW Forever look."] = "Ersetzt den bronzenen WoW-Forever-Look."
L["Monaspace Neon font"] = "Schriftart Monaspace Neon"
L["Chat tabs keep a narrower font."] = "Chat-Reiter behalten eine schmalere Schrift."
L["Class-color accent"] = "Akzent in Klassenfarbe"
L["Colors quests, meters, chat and menu bar."] = "Färbt Quests, Anzeigen, Chat und Menüleiste."
L["Pixel-perfect scale"] = "Pixelgenaue Skalierung"
L["Sharper and slightly smaller."] = "Schärfer und etwas kleiner."
L["Compact bags"] = "Kompakte Taschen"
L["EllesmereUI's compact bag view."] = "Die kompakte Taschenansicht von EllesmereUI."
L["flat style"] = "flacher Stil"
L["style (EllesmereUI options addon unavailable)"] = "Stil (EllesmereUI-Optionen-Addon nicht verfügbar)"
L["font"] = "Schriftart"
L["font (%s)"] = "Schriftart (%s)"
L["class-color accent"] = "Akzent in Klassenfarbe"
L["accent color"] = "Akzentfarbe"
L["UI scale (EllesmereUI's scale function not found)"] = "UI-Skalierung (Skalierungsfunktion von EllesmereUI nicht gefunden)"
L["UI scale"] = "UI-Skalierung"
L["UI scale %.4f"] = "UI-Skalierung %.4f"
L["compact bags (EllesmereUI Bags is not loaded)"] = "kompakte Taschen (EllesmereUI Bags ist nicht geladen)"
L["compact bags"] = "kompakte Taschen"
L["menu bar (switched off)"] = "Menüleiste (ausgeschaltet)"
L["menu bar"] = "Menüleiste"
L["menu bar (EllesmereUI DataBars is not loaded)"] = "Menüleiste (EllesmereUI DataBars ist nicht geladen)"
L["minimap"] = "Minikarte"
L["quest tracker"] = "Questverfolgung"
L["damage and healing meters"] = "Schadens- und Heilungsanzeige"
L["tooltip"] = "Tooltip"
L["unit frames"] = "Einheitenfenster"
L["unit frames (module has no settings in this profile)"] = "Einheitenfenster (Modul hat in diesem Profil keine Einstellungen)"
L["cooldown manager"] = "Abklingzeitmanager"
L["EllesmereUI version unknown"] = "EllesmereUI-Version unbekannt"
L["tested with %s"] = "getestet mit %s"
L['Shared profile "%s"'] = 'Gemeinsames Profil "%s"'
L["One profile for every character you install on."] = "Ein Profil für jeden Charakter, auf dem du installierst."
L["New profile"] = "Neues Profil"
L["A name of your choice, for example per class."] = "Ein Name deiner Wahl, zum Beispiel pro Klasse."
L["EllesmereUI uses one active profile per account."] = "EllesmereUI nutzt ein aktives Profil pro Account."
L["No supported addon is loaded."] = "Kein unterstütztes Addon geladen."
L["%d of %d"] = "%d von %d"
L["none"] = "keine"
L["The settings are written. Press Reload UI to apply them."] =
    "Die Einstellungen sind geschrieben. Klicke auf Interface neu laden, um sie anzuwenden."
L["Installed"] = "Installiert"
L["Unknown reason."] = "Unbekannter Grund."
L["Skipped: %s."] = "Übersprungen: %s."
L["Welcome"] = "Willkommen"
L["Profile"] = "Profil"
L["Theme"] = "Thema"
L["Layout"] = "Layout"
L["Look"] = "Aussehen"
L["Combat"] = "Kampf"
L["Addons"] = "Addons"
L["Install"] = "Installieren"
L["This installer sets up Aritlok UI on top of EllesmereUI in a few steps. Your current profile is copied, never changed."] =
    "Dieser Installer richtet Aritlok UI in wenigen Schritten auf Basis von EllesmereUI ein. Dein aktuelles Profil wird kopiert, nie verändert."
L["Important: after a larger Aritlok UI update you may need to run the installer again."] =
    "Wichtig: Nach einem größeren Aritlok-UI-Update musst du den Installer eventuell erneut ausführen."
L["Aritlok UI writes its settings into a copy of your current EllesmereUI profile. Use the shared profile, or create one with its own name."] =
    "Aritlok UI schreibt seine Einstellungen in eine Kopie deines aktuellen EllesmereUI-Profils. Nutze das gemeinsame Profil oder erstelle eines mit eigenem Namen."
L["Pick how the unit frame bars are colored. You can switch later by running the installer again."] =
    "Wähle, wie die Leisten der Einheitenfenster eingefärbt werden. Du kannst später wechseln, indem du den Installer erneut ausführst."
L["Choose which parts of the screen are arranged. Anything you switch off stays exactly as it is now."] =
    "Wähle, welche Bereiche des Bildschirms angeordnet werden. Alles Abgeschaltete bleibt genau so, wie es jetzt ist."
L["Style, font, accent color and scale."] = "Stil, Schrift, Akzentfarbe und Skalierung."
L["Important: the UI scale applies to your whole account, not just this profile."] =
    "Wichtig: Die UI-Skalierung gilt für deinen gesamten Account, nicht nur für dieses Profil."
L["Switch on what should be hidden while you are out of combat. It shows again in a fight, and whenever the mouse is over it."] =
    "Schalte ein, was außerhalb des Kampfes ausgeblendet werden soll. Es erscheint wieder im Kampf und immer, wenn die Maus darüber ist."
L["Aritlok UI can adjust other addons so they match. Currently supported: Questie."] =
    "Aritlok UI kann andere Addons anpassen, damit sie zum Rest passen. Derzeit unterstützt: Questie."
L["Check your choices, then press Install. Nothing is changed before that."] =
    "Prüfe deine Auswahl und klicke dann auf Installieren. Vorher wird nichts geändert."
L["Class colors, deep left to bright right."] = "Klassenfarben, links tief, rechts hell."
L["Flat dark bars, class-colored names."] = "Flache dunkle Leisten, Namen in Klassenfarbe."
L["Back"] = "Zurück"
L["Continue"] = "Weiter"
L["Reload UI"] = "Interface neu laden"
L["EllesmereUI"] = "EllesmereUI"
L["the settings page needs EllesmereUI's plugin API. Use /aui help for the chat commands."] =
    "Die Einstellungsseite braucht die Plugin-API von EllesmereUI. /aui help zeigt die Chatbefehle."
L["EllesmereUI could not open the settings page. Use /aui help for the chat commands."] =
    "EllesmereUI konnte die Einstellungsseite nicht öffnen. /aui help zeigt die Chatbefehle."
L["in combat: the settings page opens when the fight ends."] = "Im Kampf: Die Einstellungsseite öffnet sich, wenn der Kampf endet."
L["Theme, bar gradients and the menu bar."] = "Thema, Farbverläufe der Leisten und die Menüleiste."
L["version %s commands:"] = "Version %s, Befehle:"
L["usage: /aui shade on|off|<0-90>"] = "Verwendung: /aui shade on|off|<0-90>"
L["gradients %s, depth %d."] = "Farbverläufe %s, Tiefe %d."
L["usage: /aui bar on|off|top|bottom"] = "Verwendung: /aui bar on|off|top|bottom"
L["backdrop %s, %s. Run /aui install to move the menu bar with it."] =
    "Hintergrund %s, %s. Führe /aui install aus, damit die Menüleiste mitwandert."
L["usage: /aui xp <length> [offset from left]. Now %d long, starting at %d."] =
    "Verwendung: /aui xp <Länge> [Abstand von links]. Aktuell %d lang, Start bei %d."
L["XP bar %d long, starting at %d. Run /aui install so the menu bar leaves the same room for it."] =
    "EP-Leiste %d lang, Start bei %d. Führe /aui install aus, damit die Menüleiste denselben Platz freilässt."
L['theme %s, installed %s, EllesmereUI profile "%s".'] = 'Thema %s, installiert %s, EllesmereUI-Profil "%s".'
L["gradients %s (%d), backdrop %s."] = "Farbverläufe %s (%d), Hintergrund %s."
L["(tested version)"] = "(getestete Version)"
L["EllesmereUI %s, tested with %s."] = "EllesmereUI %s, getestet mit %s."
L["saved settings have not loaded yet."] = "Die gespeicherten Einstellungen sind noch nicht geladen."
L['unknown command "%s".'] = 'Unbekannter Befehl "%s".'
L["on"] = "an"
L["off"] = "aus"
L["top"] = "oben"
L["bottom"] = "unten"
L["/aui                      open the settings page (EllesmereUI panel)"] =
    "/aui                      Einstellungsseite öffnen (EllesmereUI-Fenster)"
L["/aui install              open the installer"] = "/aui install              Installer öffnen"
L["/aui shade on|off|<0-90>  bar gradients and how deep the left end gets"] =
    "/aui shade on|off|<0-90>  Farbverläufe der Leisten und Tiefe des linken Endes"
L["/aui bar on|off|top|bottom     the menu bar backdrop and XP bar"] =
    "/aui bar on|off|top|bottom     Hintergrund der Menüleiste und EP-Leiste"
L["/aui xp <length> [offset] length of the XP bar on the menu bar, and where it starts"] =
    "/aui xp <Länge> [Abstand] Länge der EP-Leiste in der Menüleiste und ihr Startpunkt"
L["/aui status               what is switched on"] = "/aui status               was eingeschaltet ist"
L["/aui probe                print which client and EllesmereUI functions this build has"] =
    "/aui probe                ausgeben, welche Client- und EllesmereUI-Funktionen dieser Build hat"
L["/aui help                 this list"] = "/aui help                 diese Liste"
L["THEME"] = "THEMA"
L["Gradient (class colors)"] = "Farbverlauf (Klassenfarben)"
L["Used the next time you run the installer. Dark switches EllesmereUI's unit frames to their dark theme."] =
    "Wird beim nächsten Durchlauf des Installers verwendet. Dunkel stellt die Einheitenfenster von EllesmereUI auf deren dunkles Thema."
L["BAR GRADIENTS"] = "FARBVERLÄUFE DER LEISTEN"
L["Gradient unit frame bars"] = "Farbverlauf auf Einheitenfenster-Leisten"
L["Deepens the left end and brightens the right end of every EllesmereUI unit frame health, power and cast bar. Off in the Dark theme."] =
    "Vertieft das linke und hellt das rechte Ende jeder Gesundheits-, Ressourcen- und Zauberleiste der EllesmereUI-Einheitenfenster auf. Im dunklen Thema aus."
L["Left end depth"] = "Tiefe des linken Endes"
L["Right end glow"] = "Leuchten des rechten Endes"
L["WHAT THE INSTALLER APPLIES"] = "WAS DER INSTALLER ANWENDET"
L["HIDDEN OUT OF COMBAT"] = "AUSSERHALB DES KAMPFES AUSGEBLENDET"
L["OTHER ADDONS"] = "ANDERE ADDONS"
L["Open the installer"] = "Installer öffnen"
L["BACKDROP"] = "HINTERGRUND"
L["Show the backdrop and XP bar"] = "Hintergrund und EP-Leiste anzeigen"
L["The fading strip behind the menu bar. The menu bar itself is an EllesmereUI DataBar."] =
    "Der auslaufende Streifen hinter der Menüleiste. Die Menüleiste selbst ist eine EllesmereUI DataBar."
L["Screen edge"] = "Bildschirmrand"
L["Bottom"] = "Unten"
L["Top"] = "Oben"
L["Run the installer again afterwards so the menu bar and the layout move with it."] =
    "Führe danach den Installer erneut aus, damit Menüleiste und Layout mitwandern."
L["Opacity"] = "Deckkraft"
L["Class-color wash"] = "Schimmer in Klassenfarbe"
L["EXPERIENCE BAR"] = "ERFAHRUNGSLEISTE"
L["Long experience bar"] = "Lange Erfahrungsleiste"
L["Replaces the DataBar's short XP block. Run the installer again after changing this."] =
    "Ersetzt den kurzen EP-Block der DataBar. Führe nach einer Änderung den Installer erneut aus."
L["Length"] = "Länge"
L["Run the installer again afterwards so the menu bar leaves the same room."] =
    "Führe danach den Installer erneut aus, damit die Menüleiste denselben Platz freilässt."
L["Start (from the left edge)"] = "Start (vom linken Rand)"
L["CLOCK"] = "UHR"
L["24-hour clock"] = "24-Stunden-Uhr"
L["Applied the next time you run the installer."] = "Wird beim nächsten Durchlauf des Installers angewendet."
L["Menu Bar"] = "Menüleiste"
