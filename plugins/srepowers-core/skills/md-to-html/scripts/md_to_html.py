#!/usr/bin/env python3
"""md-to-html — render a Markdown file to HTML and open it rendered.

Converts a Markdown file to a standalone HTML document with pandoc
(GitHub-flavored Markdown), writes `<input>.html` alongside the input by
default, then opens the result in the platform's default browser:

- WSL      → the WINDOWS default browser (that is the point on WSL, where no
             Linux browser exists): `wslview` when installed, else
             `cmd.exe /c start "" <windows-path>` with the path translated
             by `wslpath -w`. The empty "" is load-bearing — without it,
             `start` treats the first quoted argument as a window title and
             opens nothing.
- macOS    → `open`
- Linux    → `xdg-open`

Exit codes: 0 success (a failed browser-open still exits 0 — the HTML
artifact is the product and its path is printed; a WARN explains why the
open did not happen); 2 input missing, pandoc missing, or pandoc failed.
"""

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

CMD_EXE_FALLBACK = "/mnt/c/Windows/System32/cmd.exe"


def render(md_text, title):
    """Convert markdown text to a standalone HTML string via pandoc (gfm)."""
    proc = subprocess.run(
        ["pandoc", "-f", "gfm", "-s", "--metadata", "title=" + title],
        input=md_text, capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError("pandoc failed:\n" + proc.stderr)
    return proc.stdout


def default_output(input_path):
    """`notes.md` → `notes.html` in the same directory (last suffix replaced)."""
    return input_path.with_suffix(".html")


def detect_platform(version_text=None):
    """Classify where we are running. WSL is detected from /proc/version —
    checked before the native branches because a WSL kernel reports both."""
    if version_text is None:
        try:
            version_text = Path("/proc/version").read_text(errors="replace")
        except OSError:
            version_text = ""
    if "microsoft" in version_text.lower():
        return "wsl"
    if sys.platform == "darwin":
        return "macos"
    return "linux"


def wsl_windows_path(path):
    """Translate a WSL path to its Windows form via `wslpath -w`."""
    proc = subprocess.run(["wslpath", "-w", str(path)],
                          capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError("wslpath -w failed:\n" + proc.stderr)
    return proc.stdout.strip()


def open_rendered(path, platform):
    """Open the rendered file with the platform's default browser."""
    if platform == "wsl":
        wslview = shutil.which("wslview")
        if wslview:
            subprocess.run([wslview, str(path)], check=True)
            return
        cmd_exe = shutil.which("cmd.exe") or CMD_EXE_FALLBACK
        # cwd=/mnt/c/Windows: cmd.exe inherits the caller's WSL cwd as a UNC
        # path it cannot use, warning on every run; a real Windows directory
        # silences it. The open itself uses the absolute translated path.
        subprocess.run(
            [cmd_exe, "/c", "start", "", wsl_windows_path(path)],
            check=True, cwd="/mnt/c/Windows")
    elif platform == "macos":
        subprocess.run(["open", str(path)], check=True)
    elif platform == "linux":
        subprocess.run(["xdg-open", str(path)], check=True)
    else:
        print(f"WARN: unknown platform — wrote {path} but did not open a "
              "browser")


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Convert a Markdown file to standalone HTML and open it "
                    "in the default browser (WSL → Windows default browser).")
    parser.add_argument("input", help="path to the .md file")
    parser.add_argument("-o", "--output",
                        help="output .html path (default: alongside input)")
    args = parser.parse_args(argv)

    src = Path(args.input)
    if not src.is_file():
        print(f"ERROR: no such file: {src}", file=sys.stderr)
        return 2

    if shutil.which("pandoc") is None:
        print("ERROR: pandoc not found — install it first "
              "(Debian/Ubuntu: sudo apt install pandoc)", file=sys.stderr)
        return 2

    out = Path(args.output) if args.output else default_output(src)
    try:
        html = render(src.read_text(encoding="utf-8"), title=src.stem)
    except RuntimeError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2
    out.write_text(html, encoding="utf-8")
    print(f"converted: {src} -> {out}")

    try:
        open_rendered(out, detect_platform())
        print(f"opened in default browser ({detect_platform()})")
    except Exception as exc:  # best-effort: the artifact exists either way
        print(f"WARN: conversion succeeded but could not open browser: {exc}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
