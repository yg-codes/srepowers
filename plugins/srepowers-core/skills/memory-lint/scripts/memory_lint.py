#!/usr/bin/env python3
"""memory-lint — integrity checker for the file-based memory store.

Validates frontmatter schema, name-slug format and uniqueness, two-way
MEMORY.md index consistency, and [[link]] resolution. Dangling [[links]]
are INFO by design: a link to a not-yet-written memory is sanctioned as
"something worth writing later", not an error.

Exit code: 1 if any WARN finding, else 0.
"""

import os
import re
import sys
from collections import namedtuple
from pathlib import Path

Finding = namedtuple("Finding", "level rule message")

def project_slug(path):
    """Claude Code's name for a project dir. NOT the handoff store's slug,
    which drops the leading dash; the two are not interchangeable."""
    return re.sub(r"[/.]", "-", str(path))


# Honor CLAUDE_CONFIG_DIR: a session started under a non-default config dir
# keeps its memories there, and hardcoding ~/.claude lints a different store
# than the one actually loaded — silently, since both look valid.
CONFIG_ROOT = Path(os.environ.get("CLAUDE_CONFIG_DIR") or (Path.home() / ".claude"))


def nearest_store(leaf):
    """The closest <config-dir>/projects/<slug>/<leaf> at or above the cwd.

    Walk up rather than take the cwd's own slug: a subdirectory gets its own
    project dir, and that dir almost never holds the store, so anchoring on
    the cwd alone breaks every invocation from below the project root.
    Falls back to the cwd's own slug so a first run still has somewhere to go.
    """
    root = CONFIG_ROOT / "projects"
    cwd = Path.cwd().resolve()
    for parent in (cwd, *cwd.parents):
        candidate = root / project_slug(parent) / leaf
        if candidate.exists():
            return candidate
    return root / project_slug(cwd) / leaf


DEFAULT_STORE = nearest_store("memory")
VALID_TYPES = {"user", "feedback", "project", "reference"}
# the store's established convention is snake_case; the spec says kebab — accept both,
# flag only genuinely malformed names (uppercase, spaces, punctuation)
NAME_RE = re.compile(r"^[a-z0-9]+([-_][a-z0-9]+)*$")

# PII heuristics: memory files get re-read by every later tool call and travel
# wherever that context goes, so a colleague's real name/email in a memory file
# is a standing leak, not a one-time exposure. Email is a straightforward regex;
# name-shaped is inherently fuzzy, so it's scoped to contexts that actually correlate
# with a real person (a label like "Contact:", or "Name <email>" authorship form)
# rather than flagging ordinary capitalized two-word prose (e.g. "Control Tower").
EMAIL_RE = re.compile(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?"
                       r"(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?)+\b")
# Placeholder domains used intentionally for anonymized worked examples.
# RFC 2606 §3 reserves exactly these three second-level names; everything else
# that "looks like" a placeholder (test.com, domain.com, company.com,
# yourcompany.com) is an ordinary registrable domain that can hold a live
# mailbox, so whitelisting it silently exempts real addresses. Note RFC 2606 §2
# reserves the TLD `.test` — that does not extend to the .com registration.
PLACEHOLDER_EMAIL_DOMAINS = {
    "example.com", "example.org", "example.net",
}
NAME_TOKEN = r"[A-Z][a-z]+"
NAME_SPAN = rf"{NAME_TOKEN}(?:\s+{NAME_TOKEN}){{1,2}}"  # 2-3 capitalized words
# case-insensitivity is scoped to the label alternation only (inline (?i:...)) —
# applying it to the whole pattern would also lowercase-match NAME_SPAN's capital
# requirement and flag ordinary lowercase prose
# The label must start a line OR follow a dash/pipe separator. MEMORY.md index
# rows are `- [Title](file.md) — hook`, so a label there is structurally always
# mid-line: anchoring only at line start made the index's own name-PII
# unreachable, which is the one file loaded into every session. Still not a bare
# mid-sentence match — that would fire on ordinary prose ("the owner: someone
# must decide") and train readers to ignore the rule.
LABELED_NAME_RE = re.compile(
    rf"(?m)(?:^\s*|[-—–|]\s+)((?i:name|contact|author|owner|assignee|cc))"
    rf"\s*:\s*({NAME_SPAN})\b"
)
LABELED_NAME_PHRASE_RE = re.compile(
    rf"\b((?i:reported by|assigned to))\s*:?\s*({NAME_SPAN})\b"
)
# git-style authorship: "First Last <email@x.com>"
NAME_BEFORE_EMAIL_RE = re.compile(
    rf"({NAME_SPAN})\s*<([^<>@\s]+@[^<>\s]+)>"
)


def _norm(slug):
    """Treat - and _ as the same separator when resolving [[links]]."""
    return slug.replace("_", "-")


def _scan_pii(text, label, warn):
    """Flag email/name-shaped spans in one file's text.

    Extracted so MEMORY.md gets the same scan as every memory file: the index
    is loaded into context every session, making it the highest-frequency
    re-read in the store and the worst place for a standing leak.
    """
    for lineno, line in enumerate(text.splitlines(), start=1):
        for m in EMAIL_RE.finditer(line):
            domain = m.group(0).rsplit("@", 1)[-1].lower()
            if domain not in PLACEHOLDER_EMAIL_DOMAINS:
                warn("possible-pii-email",
                     f"{label}:{lineno}: email-shaped span "
                     "(value redacted from this report — a real address re-egresses "
                     "on every later read)")
        for pattern in (LABELED_NAME_RE, LABELED_NAME_PHRASE_RE):
            m = pattern.search(line)
            if m:
                warn("possible-pii-name",
                     f"{label}:{lineno}: name-shaped span near a '{m.group(1).lower()}' cue "
                     "(value redacted from this report)")
        if NAME_BEFORE_EMAIL_RE.search(line):
            warn("possible-pii-name",
                 f"{label}:{lineno}: name-shaped span before a git-style authorship email "
                 "(value redacted from this report)")


def _strip_code(text):
    """Blank out fenced and inline code so regex/shell samples aren't read as [[links]].

    A memory recording a shell idiom (`rg '[[:space:]]'`) otherwise reports a
    dangling link per bracket expression — noise that trains a reader to skip
    the INFO lines that do matter.
    """
    text = re.sub(r"```.*?```", "", text, flags=re.DOTALL)
    return re.sub(r"`[^`\n]*`", "", text)


def parse_frontmatter(text):
    """Return {name, description, type} from a ----fenced block, or None."""
    if not text.startswith("---\n"):
        return None
    end = text.find("\n---", 4)
    if end == -1:
        return None
    fm = {}
    for line in text[4:end].splitlines():
        m = re.match(r"\s*(name|description|type):\s*(.+)", line)
        if m:
            fm[m.group(1)] = m.group(2).strip()
    return fm


def lint_store(store_dir):
    """Lint one memory store directory. Returns [Finding]."""
    store = Path(store_dir)
    findings = []
    warn = lambda rule, msg: findings.append(Finding("WARN", rule, msg))
    info = lambda rule, msg: findings.append(Finding("INFO", rule, msg))

    files = sorted(p for p in store.glob("*.md") if p.name != "MEMORY.md")
    names = {}  # name slug -> filename

    for p in files:
        text = p.read_text(encoding="utf-8")
        fm = parse_frontmatter(text)
        if fm is None:
            warn("missing-frontmatter", f"{p.name}: no ----fenced frontmatter block")
            continue
        for field in ("name", "description", "type"):
            if field not in fm:
                warn("missing-field", f"{p.name}: frontmatter lacks `{field}`")
        if "type" in fm and fm["type"] not in VALID_TYPES:
            warn("bad-type", f"{p.name}: type `{fm['type']}` not in {sorted(VALID_TYPES)}")
        pm = re.match(r"(user|feedback|project|reference)_", p.name)
        if pm and fm.get("type") in VALID_TYPES and fm["type"] != pm.group(1):
            warn("prefix-type-mismatch",
                 f"{p.name}: filename prefix `{pm.group(1)}_` disagrees with type `{fm['type']}` "
                 "(store convention: the prefix matches metadata type)")
        if "name" in fm:
            if not NAME_RE.match(fm["name"]):
                warn("bad-name-format", f"{p.name}: name `{fm['name']}` is not a lowercase kebab/snake slug")
            key = _norm(fm["name"])  # foo-bar and foo_bar resolve the same [[link]]
            if key in names:
                warn("duplicate-name", f"{p.name}: name `{fm['name']}` already used by {names[key]}")
            else:
                names[key] = p.name

        _scan_pii(text, p.name, warn)

    index = store / "MEMORY.md"
    if not index.exists():
        warn("no-index", "MEMORY.md is missing — it is the index loaded each session")
        indexed = set()
    else:
        index_text = index.read_text(encoding="utf-8")
        _scan_pii(index_text, "MEMORY.md", warn)
        indexed = set(re.findall(r"\]\(([^)]+\.md)\)", index_text))
        for target in sorted(indexed):
            if not (store / target).exists():
                warn("dangling-index-entry", f"MEMORY.md links to `{target}` which does not exist")
    for p in files:
        if index.exists() and p.name not in indexed:
            warn("unindexed-file", f"{p.name}: not referenced from MEMORY.md")

    normed = {_norm(n) for n in names}
    for p in files:
        body = p.read_text(encoding="utf-8")
        for link in re.findall(r"\[\[([^\]]+)\]\]", _strip_code(body)):
            # POSIX bracket expressions ([[:space:]], [[:alnum:]]) are regex syntax,
            # not wiki-links; they only look like one because :space: contains no "]".
            if link.startswith(":") and link.endswith(":"):
                continue
            if _norm(link) not in normed:
                info("dangling-link", f"{p.name}: [[{link}]] has no memory with that name yet")

    return findings


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    store = Path(argv[0]) if argv else DEFAULT_STORE

    findings = lint_store(store)
    for f in findings:
        print(f"{f.level} {f.rule}: {f.message}")
    if not findings:
        print("no findings")
    n_files = len([p for p in store.glob('*.md') if p.name != 'MEMORY.md'])
    print(f"checked {n_files} memory files in {store}")
    return 1 if any(f.level == "WARN" for f in findings) else 0


if __name__ == "__main__":
    sys.exit(main())
