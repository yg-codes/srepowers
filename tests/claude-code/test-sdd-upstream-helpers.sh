#!/usr/bin/env bash
# Hermetic regressions for the selective superpowers v7.0.2 helper backport.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
python3 - "$ROOT" <<'PY'
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPTS = Path(sys.argv[1]) / 'plugins/srepowers-core/skills/subagent-driven-operation/scripts'


class Helpers(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.repo = self.root / 'repo'
        self.git('init', '-q', '-b', 'main', str(self.repo), cwd=self.root)
        self.plan = self.repo / 'plan.md'
        self.plan.write_text('## Task 1: First\nFIRST\n## Task 2: Second\nSECOND\n')
        self.git('add', 'plan.md')
        self.git('-c', 'user.name=Test', '-c', 'user.email=test@example.com',
                 '-c', 'commit.gpgsign=false', 'commit', '-qm', 'base')
        self.base = self.git('rev-parse', 'HEAD').stdout.strip()
        (self.repo / 'change.txt').write_text('changed\n')
        self.git('add', 'change.txt')
        self.git('-c', 'user.name=Test', '-c', 'user.email=test@example.com',
                 '-c', 'commit.gpgsign=false', 'commit', '-qm', 'change')
        self.out = self.root / 'brief.md'

    def git(self, *args, cwd=None):
        return subprocess.run(['git', *args], cwd=cwd or self.repo,
                              text=True, capture_output=True, check=True)

    def helper(self, script, *args, cwd=None, env=None):
        return subprocess.run(['bash', str(SCRIPTS / script), *map(str, args)],
                              cwd=cwd or self.repo, env=env, text=True,
                              capture_output=True, timeout=20)

    def brief(self, text, task):
        self.plan.write_text(text)
        result = self.helper('task-brief', self.plan, task, self.out)
        return result, self.out.read_text() if self.out.exists() else ''

    def test_exact_numeric_id(self):
        result, text = self.brief('## Task 6: Six\nSIX\n## Task 6b: Letter\nLETTER\n', '6')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('SIX', text)
        self.assertNotIn('LETTER', text)

    def test_exact_dotted_id(self):
        result, text = self.brief('## Task 1: One\nONE\n## Task 1.1: Dot\nDOT\n', '1')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn('DOT', text)

    def test_alphanumeric_and_dotted_ids(self):
        for task in ('A1', '6b', '2.1'):
            with self.subTest(task=task):
                result, text = self.brief(f'## Task {task}: Target\nTARGET\n## Task 9: Other\nOTHER\n', task)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn('TARGET', text)
                self.assertNotIn('OTHER', text)

    def test_nested_subtasks_and_notes(self):
        result, text = self.brief('## Task 7: Main\nMAIN\n### Task 7a: Child\nCHILD\n'
                                  '### Task notes\nNOTES\n### Task 8: Next\nNEXT\n', '7')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('CHILD', text)
        self.assertIn('NOTES', text)
        self.assertNotIn('NEXT', text)

    def test_unclosed_fence_refuses_partial_brief(self):
        result, _ = self.brief('## Task 1: First\nFIRST\n```sh\necho x\n## Task 2: Second\nSECOND\n', '1')
        self.assertEqual(result.returncode, 4, result.stderr)
        self.assertIn('never closes', result.stderr)
        self.assertFalse(self.out.exists(), 'partial brief must not survive')

    def test_unclosed_fence_hiding_requested_task(self):
        result, _ = self.brief('```sh\n## Task 1: Hidden\n', '1')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('never closes', result.stderr)

    def test_trailing_fence_warns_without_false_failure(self):
        result, text = self.brief('## Task 1: First\nFIRST\n```\n', '1')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('warning', result.stderr)
        self.assertIn('FIRST', text)

    def test_closed_fence_preserves_code(self):
        result, text = self.brief('## Task 1: First\n```md\n## Task 8: Example\n```\nEND\n'
                                  '## Task 2: Second\nSECOND\n', '1')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('## Task 8: Example', text)
        self.assertIn('END', text)
        self.assertNotIn('SECOND', text)

    def test_translated_heading_hint(self):
        result, _ = self.brief('## Tarea 1: Primero\nPRIMERO\n', '1')
        self.assertEqual(result.returncode, 3)
        self.assertIn('English word', result.stderr)
        self.assertIn('Tarea 1', result.stderr)

    def test_invalid_task_id_rejected_before_output(self):
        result = self.helper('task-brief', self.plan, '../escape')
        self.assertEqual(result.returncode, 2)
        self.assertIn('task ID', result.stderr)
        self.assertFalse((self.repo / '.srepowers').exists())

    def test_explicit_c_directory(self):
        for script, args in [('sdd-workspace', [self.plan]),
                             ('task-brief', [self.plan, '1']),
                             ('review-package', [self.plan, self.base, 'HEAD'])]:
            with self.subTest(script=script):
                result = self.helper(script, '-C', self.repo, *args, cwd=self.root)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn(str(self.repo / '.srepowers/sdd/plan'), result.stdout)

    def test_no_repository_diagnostic(self):
        for script, args in [('sdd-workspace', [self.plan]),
                             ('review-package', [self.plan, self.base, 'HEAD'])]:
            with self.subTest(script=script):
                result = self.helper(script, *args, cwd=self.root)
                self.assertEqual(result.returncode, 2, result.stderr)
                self.assertIn('working tree', result.stderr)
                self.assertIn('git said:', result.stderr)
        self.assertFalse((self.root / '.srepowers').exists())

    def test_existing_ignore_policy_preserved(self):
        base = self.repo / '.srepowers/sdd'
        base.mkdir(parents=True)
        ignore = base / '.gitignore'
        ignore.write_text('*\n!progress.md\n')
        result = self.helper('sdd-workspace', self.plan)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(ignore.read_text(), '*\n!progress.md\n')

    def test_linked_worktree_uses_execution_tree_not_plan_tree(self):
        worktree = self.root / 'linked'
        self.git('worktree', 'add', '-qb', 'linked', str(worktree))
        result = self.helper('sdd-workspace', self.plan, cwd=worktree)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), str(worktree / '.srepowers/sdd/plan'))

    def test_symlinked_cwd_uses_physical_plan_marker(self):
        link = self.root / 'alias'
        link.symlink_to(self.repo, target_is_directory=True)
        result = self.helper('sdd-workspace', '-C', link, 'plan.md', cwd=self.root)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((Path(result.stdout.strip()) / 'plan-path').read_text().strip(), 'plan.md')

    def test_review_range_guards_and_content(self):
        result = self.helper('review-package', self.plan, self.base, 'HEAD', self.out)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('+changed', self.out.read_text())
        for base, head in [('HEAD', 'HEAD'), ('HEAD', self.base)]:
            with self.subTest(base=base):
                result = self.helper('review-package', self.plan, base, head)
                self.assertEqual(result.returncode, 3)

    def test_emulated_cygpath_printing(self):
        bin_dir = self.root / 'bin'
        bin_dir.mkdir()
        shim = bin_dir / 'cygpath'
        shim.write_text('#!/bin/sh\n[ "$1" = -m ] || exit 9\nprintf "C:/native/workspace\\n"\n')
        shim.chmod(0o700)
        env = dict(os.environ, PATH=f'{bin_dir}:{os.environ["PATH"]}')
        result = self.helper('sdd-workspace', self.plan, env=env)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), 'C:/native/workspace')

    def test_sdd_repo_commit_requirement(self):
        empty = self.root / 'empty'
        self.git('init', '-q', '-b', 'main', str(empty), cwd=self.root)
        result = self.helper('sdd-repo', cwd=empty)
        self.assertEqual(result.returncode, 0, result.stderr)
        result = self.helper('sdd-repo', '--with-commit', cwd=empty)
        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertIn('first commit', result.stderr)


unittest.main(argv=[sys.argv[0]], verbosity=2)
PY
