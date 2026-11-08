#!/usr/bin/env bash
# Test the handoff skill's capture commands in an isolated Git repository.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO_ROOT/plugins/srepowers-core/skills/handoff/SKILL.md"

python3 -B - "$SKILL" <<'PY'
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest


SKILL = Path(sys.argv.pop()).read_text()


class HandoffTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="handoff-test-")
        self.addCleanup(temporary.cleanup)
        self.home = Path(temporary.name) / "home"
        self.repo = self.home / "src" / "service"
        self.repo.mkdir(parents=True)
        self.env = {key: value for key, value in os.environ.items()
                    if not key.startswith("GIT_")}
        self.env.update(HOME=str(self.home), GIT_CONFIG_NOSYSTEM="1",
                        GIT_CONFIG_GLOBAL=os.devnull, GIT_TERMINAL_PROMPT="0")
        self.git("init", "--quiet", "-b", "main")
        self.git("config", "user.name", "Example User")
        self.git("config", "user.email", "user@example.com")
        (self.repo / "config.txt").write_text("original\n")
        self.git("add", "config.txt")
        self.git("commit", "--quiet", "-m", "fixture base")

    def git(self, *arguments):
        return subprocess.check_output(["git", *arguments], cwd=self.repo,
                                       env=self.env, text=True)

    def capture(self):
        block = re.search(r"```bash\n(.*?)\n```", SKILL, re.S)
        self.assertIsNotNone(block, "missing capture command block")
        return subprocess.run(["bash", "-c", block.group(1)], cwd=self.repo,
                              env=self.env, capture_output=True, text=True)

    def test_nested_untracked_files_are_named(self):
        note = self.repo / "notes" / "nested" / "decision.md"
        note.parent.mkdir(parents=True)
        note.write_text("undecided\n")
        result = self.capture()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("?? notes/nested/decision.md", result.stdout)

    def test_staged_changes_have_diff_statistics(self):
        (self.repo / "config.txt").write_text("changed\n")
        self.git("add", "config.txt")
        result = self.capture()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("1 file changed", result.stdout)

    def test_remote_credentials_never_reach_output(self):
        secret = "example-secret"
        self.git("remote", "add", "origin",
                 f"https://example-user:{secret}@example.com/team/service.git")
        result = self.capture()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn(secret, result.stdout + result.stderr)
        self.assertIn("example.com/team/service.git", result.stdout)

    def test_remote_query_and_fragment_are_not_disclosed(self):
        self.git("remote", "add", "origin",
                 "https://example.com/team/service.git?token=example-secret#private")
        result = self.capture()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("example-secret", result.stdout + result.stderr)
        self.assertNotIn("#private", result.stdout)

    def test_rejected_remote_urls_are_omitted_without_disclosure(self):
        secret = "example-secret"
        self.git("remote", "add", "origin",
                 f"https://example-user:{secret}@example.com\uff0frepo.git")
        result = self.capture()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn(secret, result.stdout + result.stderr)
        self.assertIn("<remote omitted: unsafe to display>", result.stdout)

    def test_authority_less_remote_urls_strip_query_and_fragment(self):
        secret = "example-secret"
        self.git("remote", "add", "origin",
                 f"file:///tmp/example.git?token={secret}#hidden")
        result = self.capture()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn(secret, result.stdout + result.stderr)
        self.assertNotIn("?", result.stdout)
        self.assertNotIn("#hidden", result.stdout)
        self.assertIn("/tmp/example.git", result.stdout)

    def test_relative_remote_urls_strip_query_and_fragment(self):
        secret = "example-secret"
        self.git("remote", "add", "origin",
                 f"../local/service.git?token={secret}#hidden")
        result = self.capture()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn(secret, result.stdout + result.stderr)
        self.assertNotIn("?", result.stdout)
        self.assertIn("../local/service.git", result.stdout)

    def test_scp_like_remotes_sanitize_user_token(self):
        self.git("remote", "add", "origin",
                 "git@github.com:acme/service.git")
        result = self.capture()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("github.com:acme/service.git", result.stdout)
        self.assertNotIn("git@", result.stdout + result.stderr)

    def test_misparsed_credential_urls_are_omitted(self):
        secret = "pass@secret"
        self.git("remote", "add", "origin",
                 f"user:{secret}@example.com:team/service.git")
        result = self.capture()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn(secret, result.stdout + result.stderr)
        self.assertIn("<remote omitted: unsafe to display>", result.stdout)

    def test_malformed_port_authorities_are_omitted(self):
        self.git("remote", "add", "https",
                 "https://example.com:super-secret-token/team/service.git")
        self.git("remote", "add", "ssh",
                 "ssh://example.com:notaport/team/service.git")
        result = self.capture()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("super-secret-token", result.stdout + result.stderr)
        self.assertNotIn("notaport", result.stdout + result.stderr)
        # git remote -v prints each remote twice (fetch + push): 2 remotes -> 4 lines
        self.assertEqual(result.stdout.count("<remote omitted: unsafe to display>"), 4)

    def test_local_remote_paths_with_spaces_are_preserved(self):
        self.git("remote", "add", "origin", str(self.home / "local repos" / "service.git"))
        result = self.capture()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("local repos/service.git", result.stdout)

    def test_capture_preserves_work(self):
        (self.repo / "config.txt").write_text("staged\n")
        self.git("add", "config.txt")
        (self.repo / "scratch.txt").write_text("untracked\n")
        commands = [("rev-parse", "HEAD"), ("status", "--porcelain", "-uall"),
                    ("diff", "--cached"), ("stash", "list")]
        before = [self.git(*command) for command in commands]
        result = self.capture()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(before, [self.git(*command) for command in commands])

    def test_remote_failure_is_not_masked_by_redaction(self):
        real_git = shutil.which("git")
        fake_bin = self.home / "bin"
        fake_bin.mkdir()
        fake_git = fake_bin / "git"
        fake_git.write_text(
            "#!/usr/bin/env python3\nimport os, sys\n"
            "if sys.argv[1:2] == ['remote']: sys.exit(37)\n"
            f"os.execv({real_git!r}, [{real_git!r}, *sys.argv[1:]])\n")
        fake_git.chmod(0o755)
        self.env["PATH"] = str(fake_bin) + os.pathsep + self.env["PATH"]
        self.assertEqual(self.capture().returncode, 37)

    def test_identity_records_expected_delta(self):
        self.assertTrue("Expected delta:" in SKILL,
                        "identity template omits the expected handoff delta")

    def test_repositories_inside_home_are_allowed(self):
        self.assertFalse("**Never** under `$HOME`" in SKILL,
                         "repository paths under HOME are wrongly prohibited")
        self.assertTrue("inside the target repository or worktree" in SKILL,
                        "missing repository/worktree containment rule")

    def test_proportionality_has_a_word_target(self):
        self.assertTrue(re.search(r"at most 200 words", SKILL),
                        "missing quick-fix word cap")
        self.assertTrue(re.search(r"at most 500 words", SKILL),
                        "missing multi-file word cap")
        self.assertTrue(re.search(r"at most 700 words", SKILL),
                        "missing major-effort word cap")
        self.assertIn("Over the cap: trim before", SKILL)


unittest.main()
PY
