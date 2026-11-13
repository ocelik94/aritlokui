#!/usr/bin/env python3
"""Repository checks for AritlokUI. Standard library only; run from the
repository root:

    python3 scripts/check.py

The Test workflow runs the same script. StyLua runs separately.
Exits non-zero when a check fails; warnings do not fail the run.
"""

import glob
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lualex  # noqa: E402

FIRST_LINE = "local addonName, ns = ..."
LOCALES = ["Locales/deDE.lua", "Locales/frFR.lua"]

# Things this addon must never use (see AGENTS.md, "Hard rules").
FORBIDDEN = re.compile(
    r"COMBAT_LOG_EVENT|CombatLogGetCurrentEventInfo|SecureHandler|WrapScript|RegisterStateDriver|_onstate"
    r"|ChatFrame_OpenChat|ChatEdit_ActivateChat|SetSuperTrackedUserWaypoint"
)

# Code strings that read like text but are never shown translated: names of
# fonts, addons and media, and the English-only /aui probe output.
NOT_TEXT = {
    "Aritlok", "Aritlok Bar", "Aritlok Flat", "Expressway", "Questie", "Default",
    "events this client rejected: ", "tested with EllesmereUI ", ", plugin API ",
    # EllesmereUI's own tooltip text, looked for (Modules/Professions.lua), not shown.
    "Open Profession Book",
}
NOT_TEXT_PREFIX = ("Monaspace ",)
# Strings passed straight to these are not text either.
NOT_TEXT_CALLS = ("CreateFrame(", "CreateAnimation(", ":Register(")
# Release notes are English on purpose (like CHANGELOG.md).
NOT_TRANSLATED_FILES = {"Core/Changelog.lua"}
# Field names in BAR_FIELDS-style lists are frame keys, not text.
NOT_TEXT_FIELDS = {"Health", "Power", "Castbar", "Frame", "Button", "Alpha"}

errors, warnings = [], []


def error(where, msg):
    errors.append(f"{where}: {msg}")


def warn(where, msg):
    warnings.append(f"{where}: {msg}")


def lua_files():
    files = []
    for top in ("Core", "Locales", "Modules"):
        files += glob.glob(f"{top}/**/*.lua", recursive=True)
    return sorted(f.replace(os.sep, "/") for f in files)


def read(path):
    with open(path, encoding="utf-8") as fh:
        return fh.read()


def check_first_line(files):
    for f in files:
        first = read(f).split("\n", 1)[0].rstrip("\r")
        if first != FIRST_LINE:
            error(f"{f}:1", f"first line must be: {FIRST_LINE}")


def check_forbidden(files):
    for f in files:
        code = lualex.without_comments(read(f))
        for n, text in enumerate(code.split("\n"), 1):
            m = FORBIDDEN.search(text)
            if m:
                error(f"{f}:{n}", f"uses {m.group(0)}, which this addon must not use")


def check_toc(files):
    listed = []
    for raw in read("AritlokUI.toc").splitlines():
        line = raw.strip()
        if line and not line.startswith("#"):
            listed.append(line.replace("\\", "/"))
    for f in files:
        if f not in listed:
            error("AritlokUI.toc", f"{f} is not listed")
    for f in listed:
        if not os.path.isfile(f):
            error("AritlokUI.toc", f"{f} is listed but missing")


def locale_keys(path):
    src = read(path)
    strings, _ = lualex.scan(src)
    keys = {}
    for value, line, start, _end in strings:
        # L["key"] = ...: the string right after "L[" at the start of a line.
        if src[max(0, start - 2):start] == "L[" and src[max(0, start - 3):start - 2] in ("", "\n"):
            keys[value] = line
    return keys


def placeholders(text):
    return re.findall(r"%[-+ #0]*\d*(?:\.\d+)?[sdif%]", text)


def check_locales(files):
    tables = {path: locale_keys(path) for path in LOCALES}
    first, *rest = LOCALES
    for other in rest:
        for key in sorted(set(tables[first]) - set(tables[other])):
            error(other, f"missing translation of {key!r} (it is in {first})")
        for key in sorted(set(tables[other]) - set(tables[first])):
            error(first, f"missing translation of {key!r} (it is in {other})")

    # Placeholders keep their order in every translation.
    for path in LOCALES:
        src = read(path)
        strings, _ = lualex.scan(src)
        for idx, (value, line, start, _end) in enumerate(strings):
            is_key = src[max(0, start - 2):start] == "L["
            if is_key and value in tables[path] and idx + 1 < len(strings):
                translation = strings[idx + 1][0]
                if placeholders(value) != placeholders(translation):
                    error(f"{path}:{line}", f"placeholders differ from the English text: {value!r}")

    # Every string in the code that reads like text has a translation, and
    # every translation is still used.
    known = set(tables[first])
    used = set()
    for f in files:
        if f.startswith("Locales/") or f == "Core/Locale.lua":
            continue
        src = read(f)
        strings, _ = lualex.scan(src)
        for value, line, start, _end in strings:
            used.add(value)
            if f in NOT_TRANSLATED_FILES or value in known:
                continue
            # A direct lookup, L["..."], is text whatever it looks like.
            direct = src[max(0, start - 2):start] == "L["
            if not direct and not looks_like_text(value):
                continue
            before = src[max(0, start - 40):start]
            if before.rstrip().endswith(NOT_TEXT_CALLS) or before.rstrip().endswith('LSM:Register("font",'):
                continue
            error(f"{f}:{line}", f"{value!r} has no German or French translation")
    for key in sorted(known - used):
        warn(first, f"{key!r} is translated but not used in the code any more")


def looks_like_text(value):
    if value in NOT_TEXT or value in NOT_TEXT_FIELDS or value.startswith(NOT_TEXT_PREFIX):
        return False
    if re.search(r"[A-Za-z]{2,} [A-Za-z]{2,}", value):
        return "\\" not in value and not value.startswith("Interface")
    return re.fullmatch(r"[A-Z][a-z]+", value) is not None


def check_versions():
    found = {}
    m = re.search(r"^## Version:\s*(\S+)", read("AritlokUI.toc"), re.M)
    found["AritlokUI.toc"] = m and m.group(1)
    m = re.search(r'^ns\.VERSION = "([^"]+)"', read("Core/Core.lua"), re.M)
    found["Core/Core.lua"] = m and m.group(1)
    m = re.search(r"^## (\d+\.\d+\.\d+\S*)", read("CHANGELOG.md"), re.M)
    found["CHANGELOG.md"] = m and m.group(1)
    m = re.search(r'version = "([^"]+)"', read("Core/Changelog.lua"))
    found["Core/Changelog.lua"] = m and m.group(1)
    if len(set(found.values())) != 1 or None in found.values():
        error("version", "these must agree: " + ", ".join(f"{k} {v}" for k, v in found.items()))


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    os.chdir(root)
    files = lua_files()
    check_first_line(files)
    check_forbidden(files)
    check_toc(files)
    check_locales(files)
    check_versions()

    github = os.environ.get("GITHUB_ACTIONS") == "true"
    for kind, items in (("warning", warnings), ("error", errors)):
        for item in items:
            print(f"::{kind}::{item}" if github else f"{kind}: {item}")
    print(f"{len(files)} Lua files, {len(errors)} errors, {len(warnings)} warnings")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
