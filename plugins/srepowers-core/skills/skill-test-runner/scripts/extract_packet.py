#!/usr/bin/env python3
"""extract_packet — build a test-agent packet from a skill-test-runner fixture.

The packet holds ONLY what the test agent may see: the skill's SKILL.md, the
fixture's mocked tool responses, the standard test-run instructions, and the
trigger. The golden_output and assertions never enter the packet — they stay
with the orchestrator for evaluation. Lets the runner hand a large fixture to
an agent as one file path (the agent Reads it) instead of pasting ~100 KB
through the orchestrator's context.

Usage: python3 extract_packet.py <fixture-path> [--skill-md <path>] [-o <packet-path>]
Prints the packet path. Default packet path: $TMPDIR/skill-test-packet-<fixture-stem>-<pid>.md
"""

import argparse
import os
import sys
import tempfile
from pathlib import Path

import yaml

INSTRUCTIONS = """\
INSTRUCTIONS FOR THIS TEST RUN:
- You are being tested. All data you need is provided above under AVAILABLE DATA.
- Do NOT call Bash, kubectl, terraform, any CLI, or any MCP tool. Do NOT read or write any files other than this packet.
- When the skill instructions say to query for X, find the matching data block above and use it.
- Skip any fact-check/skill invocations, report file-saving, and Artifact steps the skill defines — produce the full report text as your final message instead.
- Follow the skill's reasoning and formatting instructions exactly.
- Produce the complete output the skill would normally produce.
"""


def _resolve_skill_md(skill):
    """Locate <skill>/SKILL.md, or None.

    Two strategies, sibling-first so a packaged install works. In any layout
    that ships skills — a repo checkout, a marketplace clone, or a cache
    install (<plugin>/<version>/skills/<name>/) — sibling skills sit beside
    this one under a shared `skills/` parent. Only the repo checkout also has
    a `plugins/` root, so that lookup is the fallback, not the primary.
    """
    if not skill:
        return None

    # 1. Sibling under the same skills/ dir: .../skills/skill-test-runner/scripts/
    here = Path(__file__).resolve()
    for parent in here.parents:
        if parent.name == "skills":
            candidate = parent / skill / "SKILL.md"
            if candidate.is_file():
                return candidate
            break

    # 2. Repo checkout: <repo>/plugins/*/skills/<skill>/SKILL.md
    for parent in here.parents:
        plugins = parent / "plugins"
        if plugins.is_dir():
            for candidate in sorted(plugins.glob(f"*/skills/{skill}/SKILL.md")):
                return candidate
    return None


def build_packet(fixture_path, skill_md_path):
    """Return packet text: SKILL.md + mocked tool responses + instructions + trigger."""
    d = yaml.safe_load(Path(fixture_path).read_text())
    blocks = []
    for tr in d.get("tool_responses") or []:
        if not isinstance(tr, dict):
            continue
        blocks.append(f"[Response for: {tr.get('match_on', '')}]")
        if tr.get("command"):
            blocks.append(f"Command: {tr['command']}")
        blocks.append(str(tr.get("response") or ""))
        blocks.append("")
    return (
        "SKILL INSTRUCTIONS:\n---\n"
        + Path(skill_md_path).read_text()
        + "\n---\n\nAVAILABLE DATA (use only this — do not call any real tools or run any commands):\n---\n"
        + "\n".join(blocks)
        + "---\n\n"
        + INSTRUCTIONS
        + (f"- Date context for this run: treat today as {d['date_context']}.\n"
           if d.get("date_context") else "")
        + f"\nTRIGGER:\n{d.get('trigger', '')}\n"
    )


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("fixture")
    ap.add_argument("--skill-md", help="path to the skill's SKILL.md "
                    "(default: resolved from fixture.skill across the repo's plugins)")
    ap.add_argument("-o", "--out")
    args = ap.parse_args(argv)

    fixture = Path(args.fixture)
    skill_md = args.skill_md
    if not skill_md:
        skill = yaml.safe_load(fixture.read_text()).get("skill", "")
        skill_md = _resolve_skill_md(skill)
        if skill_md is None:
            print(f"error: cannot locate SKILL.md for skill {skill!r}; "
                  "pass --skill-md explicitly", file=sys.stderr)
            return 2

    out = Path(args.out) if args.out else (
        Path(tempfile.gettempdir()) / f"skill-test-packet-{fixture.stem}-{os.getpid()}.md")
    out.write_text(build_packet(fixture, skill_md))
    # The packet carries the skill text and every mocked tool response, which can
    # include captured operational data. Default 0644 in a shared /tmp makes that
    # readable by every user on the host.
    os.chmod(out, 0o600)
    print(out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
