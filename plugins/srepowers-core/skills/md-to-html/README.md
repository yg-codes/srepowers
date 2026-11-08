# md-to-html

Convert a Markdown file to standalone HTML and open it rendered in your
default browser — on WSL, the **Windows** default browser. Ships as
`srepowers-core:md-to-html`. (`SKILL.md` is the agent-facing trigger doc;
this file is for humans.)

## Use cases

- Preview a report, runbook, or post-mortem draft exactly as it will read
  in a browser — GFM pipe tables and fenced code blocks included
- Check that a document's tables and fences survive rendering before sharing
- Open any generated HTML report without hand-typing fragile WSL incantations

On WSL, `xdg-open` opens nothing (no Linux browser exists in the VM), and
`cmd.exe /c start <file>` without the empty `""` argument silently treats
the path as a window title. Both look successful from inside WSL. The
script routes around both.

## How-to

In Claude Code or Codex, just ask — "render this md", "preview these notes
in a browser" — the skill triggers automatically. Directly from a shell:

```bash
python3 plugins/srepowers-core/skills/md-to-html/scripts/md_to_html.py notes.md
# custom output path (parent must exist):
python3 .../md_to_html.py report.md -o /tmp/preview.html
```

Prerequisite: pandoc — `sudo apt install pandoc` (Debian/Ubuntu).

Expected output:

```text
converted: notes.md -> notes.html
opened in default browser (wsl)
```

Output lands alongside the input (`notes.md` → `notes.html`). A failed
browser-open stays exit `0` with a WARN — the HTML artifact is the product.

### Verify

```bash
python3 -B plugins/srepowers-core/skills/md-to-html/scripts/test_md_to_html.py
```

Expected: `Ran 23 tests … OK` (on CI: `OK (skipped=1)` — the one real-pandoc
test runs only where pandoc is installed).

## Reference

| Platform | Opened with |
|----------|-------------|
| WSL | `wslview` if installed, else `cmd.exe /c start "" <path>` (Windows path via `wslpath -w`) |
| macOS | `open` |
| native Linux | `xdg-open` |

| Exit code | Meaning |
|-----------|---------|
| 0 | Success (failed browser-open is a WARN, not an error) |
| 2 | Input missing, pandoc missing, or pandoc failed |

Known limitation: the `gfm` reader passes `$…$` TeX math through unconverted —
see SKILL.md "Behavior notes" for the workaround.

---
Last Updated: 2026-09-14
