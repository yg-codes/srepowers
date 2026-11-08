"""Tests for extract_packet.py — run: PYTHONDONTWRITEBYTECODE=1 python3 -B test_extract_packet.py"""

import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from extract_packet import build_packet

FIXTURE = {
    "skill": "demo-skill",
    "trigger": "/demo-skill run the thing",
    "tool_responses": [
        {"tool": "Bash", "match_on": "cmd-one", "command": "cmd-one --flag", "response": "output ONE"},
        {"tool": "Bash", "match_on": "cmd-two", "response": "output TWO"},
    ],
    "assertions": [
        {"type": "required_section", "value": "SECRET-ASSERTION-VALUE"},
        {"type": "llm_judge", "rubric": "SECRET-RUBRIC", "pass_threshold": 0.75},
    ],
    "golden_output": "SECRET-GOLDEN body that the test agent must never see.",
}


def make_env():
    d = Path(tempfile.mkdtemp(prefix="pkt_test_"))
    skill_dir = d / "skills" / "demo-skill"
    skill_dir.mkdir(parents=True)
    (skill_dir / "SKILL.md").write_text("# Demo Skill\nDo the demo thing with THE-SKILL-BODY.")
    fx = d / "fixture-demo.json"
    fx.write_text(json.dumps(FIXTURE))
    return d, fx, skill_dir / "SKILL.md"


class TestBuildPacket(unittest.TestCase):
    def test_packet_contains_skill_mocks_trigger(self):
        _, fx, skill_md = make_env()
        packet = build_packet(fx, skill_md)
        for expected in ("THE-SKILL-BODY", "output ONE", "output TWO", "cmd-one --flag",
                         "/demo-skill run the thing", "[Response for: cmd-one]"):
            self.assertIn(expected, packet)

    def test_packet_never_leaks_golden_or_assertions(self):
        _, fx, skill_md = make_env()
        packet = build_packet(fx, skill_md)
        for banned in ("SECRET-GOLDEN", "SECRET-ASSERTION-VALUE", "SECRET-RUBRIC",
                       "golden_output", "assertions"):
            self.assertNotIn(banned, packet)

    def test_yaml_fixture_supported(self):
        d, _, skill_md = make_env()
        fy = d / "fixture-demo.yaml"
        fy.write_text(
            'skill: demo-skill\ntrigger: /demo-skill go\n'
            'tool_responses:\n  - tool: bash\n    match_on: m\n    response: yaml-resp\n'
            'assertions:\n  - type: required_section\n    value: Y-SECRET\n'
            'golden_output: Y-GOLDEN\n')
        packet = build_packet(fy, skill_md)
        self.assertIn("yaml-resp", packet)
        self.assertNotIn("Y-SECRET", packet)
        self.assertNotIn("Y-GOLDEN", packet)

    def test_date_context_injected_when_present(self):
        d, _, skill_md = make_env()
        fx2 = d / "fixture-dated.json"
        dated = dict(FIXTURE, date_context="2026-05-13")
        fx2.write_text(json.dumps(dated))
        self.assertIn("2026-05-13", build_packet(fx2, skill_md))

    def test_packet_carries_test_run_instructions(self):
        _, fx, skill_md = make_env()
        packet = build_packet(fx, skill_md)
        self.assertIn("Do NOT call Bash", packet)
        self.assertIn("TRIGGER:", packet)


class TestSkillResolution(unittest.TestCase):
    """C1: sibling-first resolution must work where there is no plugins/ root."""

    def test_resolves_sibling_in_cache_shaped_install(self):
        # <plugin>/<version>/skills/{skill-test-runner,other-skill}/ — no plugins/
        import importlib.util
        d = Path(tempfile.mkdtemp(prefix="cacheinstall_"))
        skills = d / "srepowers-core" / "5.17.0" / "skills"
        (skills / "skill-test-runner" / "scripts").mkdir(parents=True)
        (skills / "other-skill").mkdir(parents=True)
        (skills / "other-skill" / "SKILL.md").write_text("---\nname: other-skill\n---\n")
        src = Path(__file__).parent / "extract_packet.py"
        dst = skills / "skill-test-runner" / "scripts" / "extract_packet.py"
        dst.write_text(src.read_text())

        spec = importlib.util.spec_from_file_location("ep_cache", dst)
        assert spec is not None and spec.loader is not None
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)

        found = mod._resolve_skill_md("other-skill")
        self.assertIsNotNone(found, "sibling skill must resolve without a plugins/ root")
        self.assertEqual(skills / "other-skill" / "SKILL.md", found)

    def test_unknown_skill_returns_none(self):
        from extract_packet import _resolve_skill_md
        self.assertIsNone(_resolve_skill_md("no-such-skill-anywhere"))
        self.assertIsNone(_resolve_skill_md(""))


class TestPacketFilePermissions(unittest.TestCase):
    """m7: the packet holds skill text + mocked data; do not world-read it."""

    def test_packet_is_not_world_readable(self):
        import stat
        from extract_packet import main
        d = Path(tempfile.mkdtemp(prefix="packetperm_"))
        fx = d / "fixture-perm.yaml"
        fx.write_text("skill: demo\ntrigger: t\nassertions: []\ngolden_output: g\n")
        skill_md = d / "S.md"
        skill_md.write_text("---\nname: demo\n---\nbody\n")
        out = d / "packet.md"
        main([str(fx), "--skill-md", str(skill_md), "-o", str(out)])
        mode = stat.S_IMODE(out.stat().st_mode)
        self.assertEqual(0, mode & 0o077,
                         f"packet mode {oct(mode)} is group/world-readable")


if __name__ == "__main__":
    unittest.main()
