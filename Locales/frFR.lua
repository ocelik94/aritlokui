local addonName, ns = ...

-------------------------------------------------------------------------------
--  French
--  One line per English text. Placeholders (%s, %d, %.4f, %%) must stay in
--  the same order as in the English key.
-------------------------------------------------------------------------------

if ns.locale ~= "frFR" then return end

local L = ns.L

L["written for interface %s, this client reports %s. Run /aui probe and retest."] =
    "écrit pour l'interface %s, ce client indique %s. Lancez /aui probe et testez à nouveau."
L["%d%% to level %d"] = "%d%% avant le niveau %d"
L["action bars"] = "barres d'action"
L["action bars (module has no settings in this profile)"] = "barres d'action (le module n'a aucun réglage dans ce profil)"
L["Questie quest tracker in place of EllesmereUI's"] = "suivi des quêtes de Questie à la place de celui d'EllesmereUI"
L["chat"] = "discussion"
L["%d chat window(s) docked as tabs"] = "%d fenêtre(s) de discussion ancrée(s) en onglets"
L["combat visibility"] = "visibilité en combat"
L["Action bars"] = "Barres d'action"
L["Bars 1 to 5 and the stance bar. The mouse-over bar stays as it is."] =
    "Barres 1 à 5 et barre de posture. La barre au survol reste telle quelle."
L["Pet bar"] = "Barre du familier"
L["Unit frames"] = "Cadres d'unité"
L["Player, target, pet, target of target and focus."] = "Joueur, cible, familier, cible de la cible et focalisation."
L["Damage and healing meters"] = "Compteurs de dégâts et de soins"
L["Enter a profile name."] = "Saisissez un nom de profil."
L["The profile name is too long (40 characters at most)."] = "Le nom du profil est trop long (40 caractères au maximum)."
L['A profile named "%s" already exists and was not made by AritlokUI. Pick another name.'] =
    'Un profil nommé "%s" existe déjà et n\'a pas été créé par AritlokUI. Choisissez un autre nom.'
L["EllesmereUI is not loaded."] = "EllesmereUI n'est pas chargé."
L["EllesmereUI has no profile data yet. Log in once with it enabled, then try again."] =
    "EllesmereUI n'a pas encore de données de profil. Connectez-vous une fois avec EllesmereUI activé, puis réessayez."
L["This EllesmereUI version has no %s(). Run /aui probe."] = "Cette version d'EllesmereUI n'a pas de %s(). Lancez /aui probe."
L["You are in combat. Try again after the fight."] = "Vous êtes en combat. Réessayez après le combat."
L["cannot install: %s"] = "installation impossible : %s"
L["EllesmereUI did not switch to the %s profile. Nothing was changed."] =
    "EllesmereUI n'est pas passé au profil %s. Rien n'a été modifié."
L["EllesmereUI returned no profile data. Nothing was changed."] =
    "EllesmereUI n'a renvoyé aucune donnée de profil. Rien n'a été modifié."
L["note: written for EllesmereUI %s, you have %s. Some settings may not apply."] =
    "remarque : écrit pour EllesmereUI %s, vous avez %s. Certains réglages peuvent ne pas s'appliquer."
L["an unknown version"] = "une version inconnue"
L['installed the %s theme into EllesmereUI profile "%s": %s.'] = 'thème %s installé dans le profil EllesmereUI "%s" : %s.'
L["nothing"] = "rien"
L["skipped: %s."] = "ignoré : %s."
L["Dark"] = "Sombre"
L["Gradient"] = "Dégradé"
L["Player, target and cooldown rows."] = "Joueur, cible et rangées de temps de recharge."
L["Bottom rows, side blocks, mouse-over bar."] = "Rangées du bas, blocs latéraux, barre au survol."
L["Menu bar"] = "Barre de menu"
L["Needs EllesmereUI DataBars."] = "Nécessite EllesmereUI DataBars."
L["Chat"] = "Discussion"
L["Bottom left, smaller text."] = "En bas à gauche, texte plus petit."
L["Right edge"] = "Bord droit"
L["Minimap, quests, tooltip, meters."] = "Minicarte, quêtes, infobulle, compteurs."
L["Flat style"] = "Style plat"
L["Replaces the bronze WoW Forever look."] = "Remplace l'apparence bronze de WoW Forever."
L["Monaspace Neon font"] = "Police Monaspace Neon"
L["Chat tabs keep a narrower font."] = "Les onglets de discussion gardent une police plus étroite."
L["Class-color accent"] = "Accent à la couleur de classe"
L["Colors quests, meters, chat and menu bar."] = "Colore les quêtes, les compteurs, la discussion et la barre de menu."
L["Pixel-perfect scale"] = "Échelle au pixel près"
L["Sharper and slightly smaller."] = "Plus net et légèrement plus petit."
L["Compact bags"] = "Sacs compacts"
L["Compact view, opening as one bag."] = "Vue compacte, ouverte en un seul sac."
L["flat style"] = "style plat"
L["style (EllesmereUI options addon unavailable)"] = "style (addon d'options d'EllesmereUI indisponible)"
L["font"] = "police"
L["font (%s)"] = "police (%s)"
L["class-color accent"] = "accent à la couleur de classe"
L["accent color"] = "couleur d'accentuation"
L["UI scale (EllesmereUI's scale function not found)"] = "échelle de l'interface (fonction d'échelle d'EllesmereUI introuvable)"
L["UI scale"] = "échelle de l'interface"
L["UI scale %.4f"] = "échelle de l'interface %.4f"
L["compact bags (EllesmereUI Bags is not loaded)"] = "sacs compacts (EllesmereUI Bags n'est pas chargé)"
L["compact bags"] = "sacs compacts"
L["menu bar (switched off)"] = "barre de menu (désactivée)"
L["menu bar"] = "barre de menu"
L["menu bar (EllesmereUI DataBars is not loaded)"] = "barre de menu (EllesmereUI DataBars n'est pas chargé)"
L["minimap"] = "minicarte"
L["quest tracker"] = "suivi des quêtes"
L["damage and healing meters"] = "compteurs de dégâts et de soins"
L["tooltip"] = "infobulle"
L["unit frames"] = "cadres d'unité"
L["unit frames (module has no settings in this profile)"] = "cadres d'unité (le module n'a aucun réglage dans ce profil)"
L["cooldown manager"] = "gestionnaire de temps de recharge"
L["EllesmereUI version unknown"] = "Version d'EllesmereUI inconnue"
L["tested with %s"] = "testé avec %s"
L['Shared profile "%s"'] = 'Profil partagé "%s"'
L["One profile for every character you install on."] = "Un seul profil pour chaque personnage sur lequel vous installez."
L["New profile"] = "Nouveau profil"
L["A name of your choice, for example per class."] = "Un nom de votre choix, par exemple par classe."
L["EllesmereUI uses one active profile per account."] = "EllesmereUI utilise un seul profil actif par compte."
L["No supported addon is loaded."] = "Aucun addon pris en charge n'est chargé."
L["%d of %d"] = "%d sur %d"
L["none"] = "aucun"
L["The settings are written. Press Reload UI to apply them."] =
    "Les réglages sont écrits. Appuyez sur Recharger l'interface pour les appliquer."
L["Installed"] = "Installé"
L["Unknown reason."] = "Raison inconnue."
L["Skipped: %s."] = "Ignoré : %s."
L["Welcome"] = "Bienvenue"
L["Profile"] = "Profil"
L["Theme"] = "Thème"
L["Layout"] = "Disposition"
L["Look"] = "Apparence"
L["Combat"] = "Combat"
L["Addons"] = "Addons"
L["Install"] = "Installer"
L["This installer sets up AritlokUI on top of EllesmereUI in a few steps. Your current profile is copied, never changed."] =
    "Cet installateur configure AritlokUI par-dessus EllesmereUI en quelques étapes. Votre profil actuel est copié, jamais modifié."
L["Important: after a larger AritlokUI update you may need to run the installer again."] =
    "Important : après une mise à jour majeure d'AritlokUI, vous devrez peut-être relancer l'installateur."
L["AritlokUI writes its settings into a copy of your current EllesmereUI profile. Use the shared profile, or create one with its own name."] =
    "AritlokUI écrit ses réglages dans une copie de votre profil EllesmereUI actuel. Utilisez le profil partagé ou créez-en un avec son propre nom."
L["Pick how the unit frame bars are colored. You can switch later by running the installer again."] =
    "Choisissez la façon dont les barres des cadres d'unité sont colorées. Vous pourrez changer plus tard en relançant l'installateur."
L["Choose which parts of the screen are arranged. Anything you switch off stays exactly as it is now."] =
    "Choisissez les parties de l'écran à organiser. Tout ce que vous désactivez reste exactement comme maintenant."
L["Style, font, accent color and scale."] = "Style, police, couleur d'accentuation et échelle."
L["Important: the UI scale applies to your whole account, not just this profile."] =
    "Important : l'échelle de l'interface s'applique à tout votre compte, pas seulement à ce profil."
L["Switch on what should be hidden while you are out of combat. It shows again in a fight, and whenever the mouse is over it."] =
    "Activez ce qui doit être masqué hors combat. Cela réapparaît en combat et dès que la souris passe dessus."
L["AritlokUI can adjust other addons so they match."] =
    "AritlokUI peut ajuster d'autres addons pour qu'ils s'accordent avec le reste."
L["Its quest tracker replaces EllesmereUI's."] = "Son suivi des quêtes remplace celui d'EllesmereUI."
L["Guide window in the AritlokUI theme."] = "Fenêtre du guide dans le thème AritlokUI."
L["PROFESSIONS"] = "MÉTIERS"
L["Right-click for First Aid and Cooking"] = "Clic droit pour Secourisme et Cuisine"
L["Right-click the first profession on the menu bar for First Aid, the second for Cooking."] =
    "Un clic droit sur le premier métier de la barre de menu ouvre Secourisme, sur le second Cuisine."
L["General"] = "Général"
L["Changelog"] = "Nouveautés"
L["What changed in each version."] = "Ce qui a changé dans chaque version."
L["RestedXP theme"] = "Thème RestedXP"
L["Check your choices, then press Install. Nothing is changed before that."] =
    "Vérifiez vos choix, puis appuyez sur Installer. Rien n'est modifié avant cela."
L["Class colors, deep left to bright right."] = "Couleurs de classe, profondes à gauche, lumineuses à droite."
L["Flat dark bars, class-colored names."] = "Barres sombres et plates, noms à la couleur de classe."
L["Back"] = "Retour"
L["Continue"] = "Continuer"
L["Reload UI"] = "Recharger l'interface"
L["EllesmereUI"] = "EllesmereUI"
L["the settings page needs EllesmereUI's plugin API. Use /aui help for the chat commands."] =
    "la page de réglages nécessite l'API de plugins d'EllesmereUI. Utilisez /aui help pour les commandes."
L["EllesmereUI could not open the settings page. Use /aui help for the chat commands."] =
    "EllesmereUI n'a pas pu ouvrir la page de réglages. Utilisez /aui help pour les commandes."
L["in combat: the settings page opens when the fight ends."] = "en combat : la page de réglages s'ouvrira à la fin du combat."
L["Theme, bar gradients and the menu bar."] = "Thème, dégradés des barres et barre de menu."
L["version %s commands:"] = "version %s, commandes :"
L["usage: /aui shade on|off|<0-90>"] = "utilisation : /aui shade on|off|<0-90>"
L["gradients %s, depth %d."] = "dégradés %s, profondeur %d."
L["usage: /aui bar on|off|top|bottom"] = "utilisation : /aui bar on|off|top|bottom"
L["backdrop %s, %s. Run /aui install to move the menu bar with it."] = "fond %s, %s. Lancez /aui install pour que la barre de menu suive."
L["usage: /aui xp <length> [offset from left]. Now %d long, starting at %d."] =
    "utilisation : /aui xp <longueur> [décalage depuis la gauche]. Actuellement %d de long, à partir de %d."
L["XP bar %d long, starting at %d. Run /aui install so the menu bar leaves the same room for it."] =
    "Barre d'XP de %d de long, à partir de %d. Lancez /aui install pour que la barre de menu lui laisse la même place."
L['theme %s, installed %s, EllesmereUI profile "%s".'] = 'thème %s, installé %s, profil EllesmereUI "%s".'
L["gradients %s (%d), backdrop %s."] = "dégradés %s (%d), fond %s."
L["(tested version)"] = "(version testée)"
L["EllesmereUI %s, tested with %s."] = "EllesmereUI %s, testé avec %s."
L["saved settings have not loaded yet."] = "les réglages enregistrés ne sont pas encore chargés."
L['unknown command "%s".'] = 'commande inconnue "%s".'
L["on"] = "activé"
L["off"] = "désactivé"
L["top"] = "en haut"
L["bottom"] = "en bas"
L["/aui                      open the settings page (EllesmereUI panel)"] =
    "/aui                      ouvrir la page de réglages (panneau EllesmereUI)"
L["/aui install              open the installer"] = "/aui install              ouvrir l'installateur"
L["/aui shade on|off|<0-90>  bar gradients and how deep the left end gets"] =
    "/aui shade on|off|<0-90>  dégradés des barres et profondeur de l'extrémité gauche"
L["/aui bar on|off|top|bottom     the menu bar backdrop and XP bar"] =
    "/aui bar on|off|top|bottom     fond de la barre de menu et barre d'XP"
L["/aui xp <length> [offset] length of the XP bar on the menu bar, and where it starts"] =
    "/aui xp <longueur> [décalage] longueur de la barre d'XP dans la barre de menu et son point de départ"
L["/aui status               what is switched on"] = "/aui status               ce qui est activé"
L["/aui probe                print which client and EllesmereUI functions this build has"] =
    "/aui probe                afficher les fonctions du client et d'EllesmereUI présentes dans cette version"
L["/aui help                 this list"] = "/aui help                 cette liste"
L["THEME"] = "THÈME"
L["Gradient (class colors)"] = "Dégradé (couleurs de classe)"
L["Used the next time you run the installer. Dark switches EllesmereUI's unit frames to their dark theme."] =
    "Utilisé au prochain lancement de l'installateur. Sombre fait passer les cadres d'unité d'EllesmereUI à leur thème sombre."
L["BAR GRADIENTS"] = "DÉGRADÉS DES BARRES"
L["Gradient unit frame bars"] = "Dégradé sur les barres des cadres d'unité"
L["Deepens the left end and brightens the right end of every EllesmereUI unit frame health, power and cast bar. Off in the Dark theme."] =
    "Assombrit l'extrémité gauche et éclaircit l'extrémité droite de chaque barre de vie, de ressource et d'incantation des cadres d'unité d'EllesmereUI. Désactivé avec le thème Sombre."
L["Left end depth"] = "Profondeur de l'extrémité gauche"
L["Right end glow"] = "Éclat de l'extrémité droite"
L["WHAT THE INSTALLER APPLIES"] = "CE QUE L'INSTALLATEUR APPLIQUE"
L["HIDDEN OUT OF COMBAT"] = "MASQUÉ HORS COMBAT"
L["OTHER ADDONS"] = "AUTRES ADDONS"
L["Open the installer"] = "Ouvrir l'installateur"
L["BACKDROP"] = "FOND"
L["Show the backdrop and XP bar"] = "Afficher le fond et la barre d'XP"
L["The fading strip behind the menu bar. The menu bar itself is an EllesmereUI DataBar."] =
    "La bande en fondu derrière la barre de menu. La barre de menu elle-même est une DataBar EllesmereUI."
L["Screen edge"] = "Bord de l'écran"
L["Bottom"] = "Bas"
L["Top"] = "Haut"
L["Run the installer again afterwards so the menu bar and the layout move with it."] =
    "Relancez ensuite l'installateur pour que la barre de menu et la disposition suivent."
L["Opacity"] = "Opacité"
L["Class-color wash"] = "Voile à la couleur de classe"
L["EXPERIENCE BAR"] = "BARRE D'EXPÉRIENCE"
L["Long experience bar"] = "Longue barre d'expérience"
L["Replaces the DataBar's short XP block. Run the installer again after changing this."] =
    "Remplace le court bloc d'XP de la DataBar. Relancez l'installateur après avoir modifié ce réglage."
L["Length"] = "Longueur"
L["Run the installer again afterwards so the menu bar leaves the same room."] =
    "Relancez ensuite l'installateur pour que la barre de menu laisse la même place."
L["Start (from the left edge)"] = "Départ (depuis le bord gauche)"
L["CLOCK"] = "HORLOGE"
L["24-hour clock"] = "Horloge 24 heures"
L["Applied the next time you run the installer."] = "Appliqué au prochain lancement de l'installateur."
L["Menu Bar"] = "Barre de menu"
