"""A small Lua 5.1 scanner for the repository checks: finds string literals
(with their line and position) and comments. Standard library only."""


def scan(src):
    """Returns (strings, comments): strings as (value, line, start, end),
    comments as (start, end) character ranges."""
    i, n, line = 0, len(src), 1
    strings, comments = [], []
    while i < n:
        c = src[i]
        if c == "\n":
            line += 1
            i += 1
        elif src.startswith("--", i):
            j = i + 2
            level = _long_open(src, j)
            if level is not None:
                end = src.find("]" + "=" * level + "]", j)
                end = n if end < 0 else end + level + 2
            else:
                end = src.find("\n", j)
                end = n if end < 0 else end
            comments.append((i, end))
            line += src.count("\n", i, end)
            i = end
        elif c in "\"'":
            j, buf = i + 1, []
            while j < n and src[j] != c:
                if src[j] == "\\" and j + 1 < n:
                    nxt = src[j + 1]
                    buf.append({"n": "\n", "t": "\t", "\\": "\\", '"': '"', "'": "'"}.get(nxt, "\\" + nxt))
                    j += 2
                else:
                    buf.append(src[j])
                    j += 1
            strings.append(("".join(buf), line, i, j + 1))
            line += src.count("\n", i, j)
            i = j + 1
        elif c == "[" and _long_open(src, i) is not None:
            level = _long_open(src, i)
            end = src.find("]" + "=" * level + "]", i)
            end = n if end < 0 else end + level + 2
            line += src.count("\n", i, end)
            i = end
        else:
            i += 1
    return strings, comments


def without_comments(src):
    """The source with every comment blanked out (newlines kept)."""
    _, comments = scan(src)
    out, last = [], 0
    for start, end in comments:
        out.append(src[last:start])
        out.append("".join(ch if ch == "\n" else " " for ch in src[start:end]))
        last = end
    out.append(src[last:])
    return "".join(out)


def _long_open(src, i):
    if i >= len(src) or src[i] != "[":
        return None
    j = i + 1
    while j < len(src) and src[j] == "=":
        j += 1
    if j < len(src) and src[j] == "[":
        return j - i - 1
    return None
