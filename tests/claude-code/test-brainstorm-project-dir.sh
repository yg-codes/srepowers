#!/usr/bin/env bash
# Exercise the launcher with a fake node: no server, socket or browser starts.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
python3 - "$ROOT" <<'PY'
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

LAUNCHER = Path(sys.argv[1]) / 'plugins/srepowers-core/skills/brainstorming-operations/scripts/start-server.sh'


class ProjectDirectory(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        bin_dir = self.root / 'bin'
        bin_dir.mkdir()
        self.capture = self.root / 'capture.json'
        fake = bin_dir / 'node'
        fake.write_text('#!/usr/bin/env python3\nimport json, os\n'
                        'from pathlib import Path\n'
                        'Path(os.environ["TEST_CAPTURE"]).write_text(json.dumps({k: os.environ[k] '
                        'for k in ("BRAINSTORM_DIR", "BRAINSTORM_PORT_FILE", "BRAINSTORM_TOKEN_FILE")}))\n')
        fake.chmod(0o700)
        self.env = dict(os.environ, PATH=f'{bin_dir}:{os.environ["PATH"]}',
                        TEST_CAPTURE=str(self.capture))

    def launch(self, path):
        return subprocess.run(['bash', str(LAUNCHER), '--project-dir', str(path), '--foreground'],
                              cwd=self.root, env=self.env, text=True,
                              capture_output=True, timeout=15)

    def test_relative_project_is_resolved_before_script_cd(self):
        result = self.launch('new project')
        self.assertEqual(result.returncode, 0, result.stderr)
        data = json.loads(self.capture.read_text())
        project = self.root / 'new project'
        for key, value in data.items():
            self.assertTrue(Path(value).is_absolute(), (key, value))
            self.assertTrue(Path(value).is_relative_to(project), (key, value))
        self.assertTrue((Path(data['BRAINSTORM_DIR']) / 'state/server.pid').is_file())
        self.assertEqual(result.stderr, '')

    def test_file_instead_of_directory_fails_before_node(self):
        target = self.root / 'file'
        target.write_text('preserve\n')
        result = self.launch(target)
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn('Cannot create or enter --project-dir', result.stdout)
        self.assertFalse(self.capture.exists())
        self.assertEqual(target.read_text(), 'preserve\n')


unittest.main(argv=[sys.argv[0]], verbosity=2)
PY
