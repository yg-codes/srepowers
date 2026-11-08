---
name: md-to-html
description: Use when converting a Markdown file to HTML and opening the rendered result — "render this md", "convert to html and open it", "preview these notes in a browser", "show me the rendered report". Handles the WSL case, where the browser is the Windows default (Chrome, Edge, …), not a Linux one.
---

# md-to-html

Renders a Markdown file to a standalone HTML document with pandoc and opens it
in the platform's default browser — which on WSL means the **Windows** browser.
Replaces the two ways this routinely goes wrong: hand-assembled HTML that loses
GFM tables and fences, and `xdg-open` on WSL, which silently opens nothing
because no Linux browser exists inside the VM.

**Announce at start:** "I'm using the md-to-html skill to render this as HTML."

## Why this is a skill, not a one-liner

The conversion is `pandoc -f gfm -s` — trivial. The skill exists because of
the **open step** on WSL: the HTML must cross the VM boundary with a
Windows-translated path, and the naive attempts all fail quietly. `xdg-open`
on WSL finds no browser; `start` without its empty `""` argument treats the
file path as a window title and opens nothing. Both look like "ran fine" from
inside WSL. The script routes all of it and reports what it did.

## Usage

```bash
python3 scripts/md_to_html.py notes.md                  # → notes.html, opened
python3 scripts/md_to_html.py report.md -o /tmp/r.html  # custom output path
```

Run its tests with `python3 -B scripts/test_md_to_html.py`.

Platform routing, decided automatically from `/proc/version`:

| Platform | Opened with |
|----------|-------------|
| WSL | `wslview` if installed, else `cmd.exe /c start "" "$(wslpath -w …)"` |
| macOS | `open` |
| native Linux | `xdg-open` |

On WSL the default browser is whatever Windows has associated with `.html` —
Chrome, Edge, or Firefox — so the file opens rendered on the Windows desktop.

## Behavior notes

- **Output defaults to alongside the input**: `notes.md` → `notes.html`
  (only the last suffix replaced). `-o` overrides; the parent directory of
  `-o` must already exist (matches `pandoc -o`; no `mkdir` is implied).
- **Exit codes**: `0` success, `2` input missing, pandoc missing, or pandoc
  failed. Errors go to stderr.
- **A failed browser-open is a WARN, not an error** (exit stays `0`): the
  HTML artifact is the product and its path is printed. Headless runs on
  hosts without a desktop degrade to "file written" with the reason stated.
- **pandoc is a hard dependency** (GFM tables + fenced blocks survive only
  via a real converter; no hand-rolled fallback). Install:
  `sudo apt install pandoc`.
- **Known limitation — TeX math.** The `gfm` reader passes `$…$` math through
  unconverted (verified: `$\sqrt{3x-1}$` stays literal). pandoc's `markdown`
  reader does convert math, but changes `$`-delimiter parsing, so plain
  two-amount prose (e.g. `$5 and $10 per unit`) could be misread; the safer
  default for reports and docs is GFM without math. If a document genuinely
  needs TeX math, say so and convert that file explicitly with
  `pandoc -f markdown+tex_math_dollars` rather than changing the script.

## Common mistakes

- **Hand-writing the HTML wrapper** for a preview instead of running the
  script — fenced blocks and pipe tables get mangled, and the result silently
  differs from what GitHub or the reader's renderer shows.
- **Reaching for `xdg-open` on WSL.** It exits without opening anything —
  there is no Linux browser in the VM. Let the script's platform routing
  decide.
- **Retyping the `cmd.exe start` incantation from memory and dropping the
  empty `""`.** `start` then consumes the first quoted argument as a window
  title; the command "succeeds" and no window appears.

## Where this helps

Previewing `srepowers-core:sre-readme` or `srepowers-core:post-mortem-writer`
output as it will read in a browser, rendering runbook drafts for review, and
opening any generated HTML report — including the one
`srepowers-swe:improve-codebase-architecture` (if installed) writes to `$TMPDIR`.
