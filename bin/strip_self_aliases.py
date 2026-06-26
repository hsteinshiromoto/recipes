#!/usr/bin/env python3
"""Strip self-referential aliases from Quartz content before building.

An alias whose slug equals the note's own filename slug makes Quartz emit a
``<meta http-equiv="refresh">`` redirect page at that slug. Because the slug is
identical to the real page, the redirect overwrites the content and points to
itself, producing an infinite reload loop in the browser.

This script removes *only* those self-referential aliases, leaving every
genuine alias (synonyms that resolve to a different slug) untouched. It is run
in CI against the copied ``content`` directory, so the Obsidian vault is never
modified and the Obsidian "Linter" plugin can keep re-adding title aliases
without breaking the deployed site.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import List, Tuple

ALIAS_RE = re.compile(r"^(?P<key>alias|aliases):(?P<rest>.*)$")
_CSV_SPLIT = re.compile(r',(?=(?:[^"]*"[^"]*")*[^"]*$)')
_NEEDS_QUOTE = re.compile(r"""[,:\[\]{}#&*!|>%@`"']""")


def slugify(value: str) -> str:
    """Approximate Quartz v5 slugification for a single path segment.

    Lower-cases the value, turns runs of whitespace into single hyphens,
    expands a couple of special characters and drops anything outside the safe
    slug alphabet. Only used to compare an alias against a note's own slug, so
    both sides pass through this identical transform.

    Args:
        value: Raw alias text or filename stem.

    Returns:
        The slugified string.

    Example:
        >>> slugify("Scallion Noodles")
        'scallion-noodles'
        >>> slugify("Prik Nam Pla")
        'prik-nam-pla'
        >>> slugify("green onion")
        'green-onion'
    """
    s = value.strip().strip("\"'").strip()
    s = s.replace("&", "-and-").replace("%", "-percent")
    s = s.replace("?", "").replace("#", "")
    s = re.sub(r"\s+", "-", s).lower()
    s = re.sub(r"[^a-z0-9._/-]", "", s)
    s = re.sub(r"-{2,}", "-", s).strip("-")
    return s


def dequote(item: str) -> str:
    """Remove a single matching pair of surrounding quotes.

    Args:
        item: A possibly quoted YAML scalar.

    Returns:
        The unquoted, stripped value.

    Example:
        >>> dequote('"Coffee Filter"')
        'Coffee Filter'
        >>> dequote("Curau")
        'Curau'
    """
    s = item.strip()
    if len(s) >= 2 and s[0] == s[-1] and s[0] in "\"'":
        s = s[1:-1]
    return s.strip()


def split_csv(value: str) -> List[str]:
    """Split a comma-separated list, ignoring commas inside double quotes.

    Args:
        value: Inner text of an inline YAML flow list (without the brackets).

    Returns:
        The non-empty, stripped items.

    Example:
        >>> split_csv('Scallion, green onion, green onions')
        ['Scallion', 'green onion', 'green onions']
        >>> split_csv('"What\\'s, this", other')
        ['"What\\'s, this"', 'other']
    """
    return [p.strip() for p in _CSV_SPLIT.split(value) if p.strip()]


def parse_alias_field(fm_lines: List[str], idx: int) -> Tuple[List[str], int]:
    """Parse an ``alias``/``aliases`` field into its list of values.

    Handles the three shapes seen in the vault: an inline flow list
    (``[a, b]``), a bare scalar (``Curau``) and an indented block list
    (``- a`` on following lines).

    Args:
        fm_lines: Frontmatter lines (between the ``---`` fences).
        idx: Index of the line holding the alias key.

    Returns:
        A tuple of (values, end_index) where end_index is exclusive: the index
        of the first line that is not part of this field.

    Example:
        >>> parse_alias_field(["alias: [Pho]"], 0)
        (['Pho'], 1)
        >>> parse_alias_field(["aliases:", "  - Scallion", "  - green onion"], 0)
        (['Scallion', 'green onion'], 3)
    """
    match = ALIAS_RE.match(fm_lines[idx])
    if match is None:
        return [], idx + 1
    rest = match.group("rest").strip()
    if rest.startswith("["):
        inner = rest[1:].rsplit("]", 1)[0]
        return [dequote(x) for x in split_csv(inner)], idx + 1
    if rest:
        return [dequote(rest)], idx + 1
    items: List[str] = []
    j = idx + 1
    while j < len(fm_lines) and re.match(r"^\s*-\s+", fm_lines[j]):
        items.append(dequote(re.sub(r"^\s*-\s+", "", fm_lines[j])))
        j += 1
    return items, j


def render_alias(key: str, items: List[str]) -> List[str]:
    """Render an alias field back to frontmatter line(s).

    Emits an empty ``key:`` when no values remain, otherwise a single inline
    flow list, quoting items that contain YAML-significant characters.

    Args:
        key: The original key name (``alias`` or ``aliases``).
        items: The values to keep.

    Returns:
        One or more frontmatter lines.

    Example:
        >>> render_alias("alias", [])
        ['alias:']
        >>> render_alias("aliases", ["green onion", "scallions"])
        ['aliases: [green onion, scallions]']
    """
    if not items:
        return [f"{key}:"]
    rendered = []
    for item in items:
        if item == "" or item != item.strip() or _NEEDS_QUOTE.search(item):
            rendered.append('"' + item.replace('"', '\\"') + '"')
        else:
            rendered.append(item)
    return [f"{key}: [{', '.join(rendered)}]"]


def process(path: Path) -> Tuple[bool, List[str]]:
    """Remove self-referential aliases from one markdown file in place.

    Only the alias field is rewritten; all other frontmatter (dates, tags, the
    body) is preserved verbatim. A field is left untouched unless it actually
    contains a self-referential alias.

    Args:
        path: Markdown file to sanitise.

    Returns:
        A tuple of (changed, removed) where ``changed`` is whether the file was
        rewritten and ``removed`` lists the aliases that were dropped.

    Example:
        >>> import tempfile, pathlib
        >>> p = pathlib.Path(tempfile.mkdtemp()) / "Pho.md"
        >>> _ = p.write_text("---\\nalias: [Pho]\\n---\\nbody\\n")
        >>> process(p)
        (True, ['Pho'])
        >>> p.read_text()
        '---\\nalias:\\n---\\nbody\\n'
    """
    text = path.read_text(encoding="utf-8")
    lines = text.split("\n")
    if not lines or lines[0].strip() != "---":
        return False, []
    close = next((i for i in range(1, len(lines)) if lines[i].strip() == "---"), None)
    if close is None:
        return False, []

    own_slug = slugify(path.stem)
    fm = lines[1:close]
    out_fm: List[str] = []
    removed: List[str] = []
    changed = False
    i = 0
    while i < len(fm):
        match = ALIAS_RE.match(fm[i])
        if match is None:
            out_fm.append(fm[i])
            i += 1
            continue
        key = match.group("key")
        items, end = parse_alias_field(fm, i)
        kept = [it for it in items if slugify(it) != own_slug]
        if len(kept) != len(items):
            removed.extend(it for it in items if slugify(it) == own_slug)
            out_fm.extend(render_alias(key, kept))
            changed = True
        else:
            out_fm.extend(fm[i:end])
        i = end

    if not changed:
        return False, []
    path.write_text("\n".join([lines[0]] + out_fm + lines[close:]), encoding="utf-8")
    return True, removed


def main(argv: List[str]) -> int:
    """Sanitise every markdown file under a content directory.

    Args:
        argv: Process arguments; ``argv[1]`` must be the content directory.

    Returns:
        Process exit code (0 on success, 2 on usage error).

    Example:
        >>> main(["prog"])
        2
    """
    if len(argv) != 2:
        print("usage: strip_self_aliases.py <content-dir>", file=sys.stderr)
        return 2
    root = Path(argv[1])
    if not root.is_dir():
        print(f"error: not a directory: {root}", file=sys.stderr)
        return 2

    files_changed = 0
    total_removed = 0
    for md in sorted(root.rglob("*.md")):
        changed, removed = process(md)
        if changed:
            files_changed += 1
            total_removed += len(removed)
            print(f"  {md.relative_to(root)}: removed {removed}")
    print(
        f"strip_self_aliases: {files_changed} file(s) updated, "
        f"{total_removed} self-alias(es) removed"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
