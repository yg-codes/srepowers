"""Tests for md_to_html.py — run: PYTHONDONTWRITEBYTECODE=1 python3 -B test_md_to_html.py

Every subprocess call is mocked; no test opens a browser or needs pandoc to
run, except the one real-render test, which runs only where pandoc exists
(this repo's workstations). CI runners ship no pandoc, so it skips there —
the CI log shows `OK (skipped=1)`.
"""

import io
import shutil
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import md_to_html
from md_to_html import default_output, detect_platform, main, render

SAMPLE_MD = ("# Report\n\nSome *body* text.\n\n"
             "| A | B |\n|---|---|\n| 1 | 2 |\n\n"
             "```bash\necho hi\n```\n")


class _Proc:
    """Minimal subprocess.CompletedProcess stand-in."""

    def __init__(self, stdout="", stderr="", returncode=0):
        self.stdout = stdout
        self.stderr = stderr
        self.returncode = returncode


class _Recorder:
    """Collects argv lists passed to a fake subprocess.run."""

    def __init__(self, result=None):
        self.calls = []
        self.result = result or _Proc(stdout="")

    def __call__(self, argv, **kwargs):
        self.calls.append((argv, kwargs))
        return self.result


class TestDefaultOutput(unittest.TestCase):
    def test_md_becomes_html_alongside(self):
        self.assertEqual(Path("/tmp/notes/notes.html"),
                         default_output(Path("/tmp/notes/notes.md")))

    def test_multi_dot_md_replaces_only_last_suffix(self):
        self.assertEqual(Path("/tmp/a/foo.bar.html"),
                         default_output(Path("/tmp/a/foo.bar.md")))

    def test_custom_output_flag_wins(self):
        # -o is handled in main(); here we just pin that default_output
        # itself never invents a path for a non-.html target.
        self.assertEqual(Path("/tmp/x/y.md.html"),
                         default_output(Path("/tmp/x/y.md.html")))


class TestRender(unittest.TestCase):
    def test_invokes_pandoc_gfm_standalone_with_title(self):
        rec = _Recorder(_Proc(stdout="<html>out</html>"))
        orig = md_to_html.subprocess.run
        md_to_html.subprocess.run = rec
        try:
            out = render(SAMPLE_MD, "Report")
        finally:
            md_to_html.subprocess.run = orig
        self.assertEqual([(["pandoc", "-f", "gfm", "-s",
                            "--metadata", "title=Report"],
                           {"input": SAMPLE_MD, "capture_output": True,
                            "text": True})],
                         rec.calls)
        self.assertEqual("<html>out</html>", out)

    def test_pandoc_failure_raises_with_stderr(self):
        rec = _Recorder(_Proc(stdout="", stderr="pandoc: boom", returncode=43))
        orig = md_to_html.subprocess.run
        md_to_html.subprocess.run = rec
        try:
            with self.assertRaises(RuntimeError) as ctx:
                render(SAMPLE_MD, "Report")
        finally:
            md_to_html.subprocess.run = orig
        self.assertIn("pandoc: boom", str(ctx.exception))

    @unittest.skipUnless(shutil.which("pandoc"), "pandoc not installed")
    def test_real_render_produces_standalone_html(self):
        """Proves the direction you might break: a real conversion, not just
        the right argv. A missing one of these is a silent-degradation class:
        e.g. gfm tables silently dropped would pass the argv-only test."""
        out = render(SAMPLE_MD, "Report")
        self.assertIn("<!DOCTYPE html>", out)
        self.assertIn("<h1", out)
        self.assertIn("<pre", out)  # the fenced block must survive
        self.assertIn("<title>Report</title>", out)
        self.assertIn("<table>", out)  # gfm table survived the conversion


class TestDetectPlatform(unittest.TestCase):
    def test_proc_version_microsoft_means_wsl(self):
        self.assertEqual("wsl", detect_platform(
            "Linux version 6.6.87.2-microsoft-standard-WSL2"))

    def test_plain_linux_text_means_linux(self):
        self.assertEqual("linux", detect_platform(
            "Linux version 6.1.0-vanilla (gcc)"))

    def test_no_proc_version_and_darwin(self):
        orig = sys.platform
        sys.platform = "darwin"
        try:
            self.assertEqual("macos", detect_platform(version_text=""))
        finally:
            sys.platform = orig

    def test_empty_text_on_linux_host_is_linux(self):
        self.assertEqual("linux", detect_platform(version_text=""))


class TestOpenDispatch(unittest.TestCase):
    """The platform routing is the reason this skill exists — pin every arm."""

    def _patch(self, rec, which_map, wslpath=None):
        self._saved = (md_to_html.subprocess.run, md_to_html.shutil.which,
                       md_to_html.wsl_windows_path)
        md_to_html.subprocess.run = rec
        md_to_html.shutil.which = lambda name: which_map.get(name)
        if wslpath is not None:
            md_to_html.wsl_windows_path = lambda p: wslpath

    def _restore(self):
        (md_to_html.subprocess.run, md_to_html.shutil.which,
         md_to_html.wsl_windows_path) = self._saved

    def test_wsl_prefers_wslview(self):
        rec = _Recorder()
        self._patch(rec, {"wslview": "/usr/bin/wslview"})
        try:
            md_to_html.open_rendered(Path("/tmp/x.html"), "wsl")
        finally:
            self._restore()
        self.assertEqual([(["/usr/bin/wslview", "/tmp/x.html"],
                           {"check": True})], rec.calls)

    def test_wsl_falls_back_to_cmd_exe_start(self):
        rec = _Recorder()
        self._patch(rec, {"cmd.exe": "/mnt/c/Windows/System32/cmd.exe"},
                    wslpath=r"\\wsl.localhost\Debian\tmp\x.html")
        try:
            md_to_html.open_rendered(Path("/tmp/x.html"), "wsl")
        finally:
            self._restore()
        self.assertEqual(
            [(["/mnt/c/Windows/System32/cmd.exe", "/c", "start", "",
               r"\\wsl.localhost\Debian\tmp\x.html"],
              {"check": True, "cwd": "/mnt/c/Windows"})],
            rec.calls)

    def test_wsl_cmd_exe_missing_uses_absolute_mnt_path(self):
        rec = _Recorder()
        self._patch(rec, {}, wslpath=r"\\wsl.localhost\Debian\tmp\x.html")
        try:
            md_to_html.open_rendered(Path("/tmp/x.html"), "wsl")
        finally:
            self._restore()
        self.assertEqual(
            [(["/mnt/c/Windows/System32/cmd.exe", "/c", "start", "",
               r"\\wsl.localhost\Debian\tmp\x.html"],
              {"check": True, "cwd": "/mnt/c/Windows"})],
            rec.calls)

    def test_macos_uses_open(self):
        rec = _Recorder()
        self._patch(rec, {})
        try:
            md_to_html.open_rendered(Path("/tmp/x.html"), "macos")
        finally:
            self._restore()
        self.assertEqual([(["open", "/tmp/x.html"], {"check": True})],
                         rec.calls)

    def test_linux_uses_xdg_open(self):
        rec = _Recorder()
        self._patch(rec, {})
        try:
            md_to_html.open_rendered(Path("/tmp/x.html"), "linux")
        finally:
            self._restore()
        self.assertEqual([(["xdg-open", "/tmp/x.html"], {"check": True})],
                         rec.calls)

    def test_unknown_platform_skips_open_without_error(self):
        rec = _Recorder()
        self._patch(rec, {})
        try:
            md_to_html.open_rendered(Path("/tmp/x.html"), "unknown")
        finally:
            self._restore()
        self.assertEqual([], rec.calls)  # nothing launched, no crash


class TestWslWindowsPath(unittest.TestCase):
    def test_translates_via_wslpath_dash_w(self):
        # stdout ends in a real newline (what a subprocess returns), which
        # wsl_windows_path must strip — hence the concatenation, not a raw \n.
        fake = r"\\wsl.localhost\Debian\tmp\a.html" + "\n"
        rec = _Recorder(_Proc(stdout=fake))
        orig = md_to_html.subprocess.run
        md_to_html.subprocess.run = rec
        try:
            win = md_to_html.wsl_windows_path(Path("/tmp/a.html"))
        finally:
            md_to_html.subprocess.run = orig
        self.assertEqual(r"\\wsl.localhost\Debian\tmp\a.html", win)
        self.assertEqual(
            [(["wslpath", "-w", "/tmp/a.html"],
              {"capture_output": True, "text": True})],
            rec.calls)

    def test_wslpath_failure_raises(self):
        rec = _Recorder(_Proc(stdout="", stderr="no such", returncode=1))
        orig = md_to_html.subprocess.run
        md_to_html.subprocess.run = rec
        try:
            with self.assertRaises(RuntimeError):
                md_to_html.wsl_windows_path(Path("/tmp/a.html"))
        finally:
            md_to_html.subprocess.run = orig


class TestMain(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.md = Path(self.tmp.name) / "notes.md"
        self.md.write_text(SAMPLE_MD, encoding="utf-8")
        self._saved = (md_to_html.open_rendered, md_to_html.shutil.which,
                       md_to_html.render, md_to_html.detect_platform)
        self.opened = []
        # Hermetic: main()'s pandoc call is mocked here — the runner has no
        # pandoc and these tests verify main's logic (write, open, rc), not
        # the conversion, which test_real_render covers where pandoc exists.
        md_to_html.render = lambda text, title: f"<html>{title}</html>"

    def tearDown(self):
        (md_to_html.open_rendered, md_to_html.shutil.which,
         md_to_html.render, md_to_html.detect_platform) = self._saved

    def _no_open(self, path, platform):
        self.opened.append((Path(path), platform))

    def test_converts_writes_and_opens(self):
        md_to_html.open_rendered = self._no_open
        md_to_html.shutil.which = lambda n: "/usr/bin/pandoc" if n == "pandoc" else None
        md_to_html.detect_platform = lambda version_text=None: "linux"
        buf = io.StringIO()
        with redirect_stdout(buf):
            rc = main([str(self.md)])
        out = self.md.with_suffix(".html")
        self.assertEqual(0, rc)
        self.assertTrue(out.exists())
        html = out.read_text(encoding="utf-8")
        self.assertIn("<html>notes</html>", html)  # render() output, verbatim
        self.assertEqual([(out, "linux")], self.opened)
        self.assertIn(str(out), buf.getvalue())

    def test_custom_output_path(self):
        md_to_html.open_rendered = self._no_open
        md_to_html.shutil.which = lambda n: "/usr/bin/pandoc" if n == "pandoc" else None
        custom = Path(self.tmp.name) / "custom.html"  # parent must exist —
        # the script matches `pandoc -o` and does not mkdir parents
        buf = io.StringIO()
        with redirect_stdout(buf):
            rc = main([str(self.md), "-o", str(custom)])
        self.assertEqual(0, rc)
        self.assertTrue(custom.exists())

    def test_missing_input_exits_2(self):
        out, err = io.StringIO(), io.StringIO()
        with redirect_stdout(out), redirect_stderr(err):
            rc = main(["/nonexistent/no-such-file.md"])
        self.assertEqual(2, rc)
        self.assertIn("no such file", err.getvalue().lower())

    def test_no_pandoc_exits_2_with_install_hint(self):
        md_to_html.open_rendered = self._no_open
        md_to_html.shutil.which = lambda n: None
        out, err = io.StringIO(), io.StringIO()
        with redirect_stdout(out), redirect_stderr(err):
            rc = main([str(self.md)])
        self.assertEqual(2, rc)
        self.assertIn("apt install pandoc", err.getvalue().lower())

    def test_open_failure_warns_but_conversion_succeeds(self):
        md_to_html.shutil.which = lambda n: "/usr/bin/pandoc" if n == "pandoc" else None

        def boom(path, platform):
            raise RuntimeError("xdg-open: no method available")

        md_to_html.open_rendered = boom
        buf = io.StringIO()
        with redirect_stdout(buf):
            rc = main([str(self.md)])
        out = self.md.with_suffix(".html")
        self.assertEqual(0, rc)  # the artifact exists; the open is best-effort
        self.assertTrue(out.exists())
        self.assertIn("warn", buf.getvalue().lower())


if __name__ == "__main__":
    unittest.main()
