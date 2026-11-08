---
name: pdf-to-md
description: Convert PDF documents to Markdown using a local docling + RapidOCR setup. Use this whenever the user wants to turn a PDF into Markdown or plain text — extract text/tables/headings from a PDF, get a PDF's content as .md, prep a PDF for an LLM or RAG pipeline, OCR a scanned PDF to readable text, or convert one or many PDFs to markdown in the current directory. Trigger on phrases like "convert this pdf to markdown", "extract text from pdf", "turn pdf into md", "ocr this pdf", "get the content of this pdf", or any request to read/extract/transform a PDF into text or markdown form. Prefer this over generic PDF libraries because it uses the user's tuned local docling stack with better table and OCR accuracy than pypdf/pdfplumber/pytesseract.
---

# PDF to Markdown (docling + RapidOCR)

Convert PDFs to clean Markdown using the user's local, verified docling + RapidOCR
environment. Works from any directory — it calls a pinned venv by absolute path.

## When to use

- "Convert this PDF to Markdown" / "extract the text from this PDF"
- "Turn these PDFs into .md files" (one or many; or a whole directory)
- "OCR this scanned PDF" / "make this scanned PDF readable"
- "Get this PDF ready for the LLM" / "prep for RAG"

This produces structured Markdown (headings, tables, reading order). It is
**read-only extraction** — it does not merge, split, rotate, encrypt, or author
PDFs (use the `pdf` skill or qpdf/pypdf for those file-manipulation tasks).

## How to run

Always invoke the venv's Python directly by absolute path. Do not rely on PATH,
`source activate`, or the caller's working directory — the whole point of this
skill is that it works anywhere.

```bash
~/.local/docling-venv/bin/python ~/.claude/skills/pdf-to-md/scripts/convert.py <source...> [options]
```

**Arguments:**
- `source` — one or more PDF files and/or directories (a directory converts all `*.pdf` in it)
- `-o <dir>` / `--out <dir>` — write `.md` files to this directory (default: next to each source PDF)
- `--no-ocr` — never OCR; native text layer only (faster, but fails on image-only/scanned PDFs)
- `--force-ocr` — OCR every page even if a text layer exists (use when the text layer is garbage glyphs)
- `--stdout` — also print Markdown to stdout

## OCR policy (let the tool decide by default)

Docling runs OCR **only when a page has no usable text layer**. This means:
- **Digital-native PDFs** (exported from Word/LaTeX, real text inside): fast native
  extraction, no OCR, near-perfect accuracy.
- **Scanned/image-only PDFs** (photographs of pages, old scans): transparently OCRs
  via RapidOCR. First run downloads the layout/table model weights from Hugging Face.

So: **run without `--no-ocr` / `--force-ocr` first.** Only reach for the flags if:
- Conversion is slow on a known digital PDF → `--no-ocr` to skip OCR detection.
- Output looks like garbled characters despite an apparent text layer → `--force-ocr`.

## Examples

```bash
# One PDF, Markdown written next to it (report.pdf -> report.md)
~/.local/docling-venv/bin/python ~/.claude/skills/pdf-to-md/scripts/convert.py report.pdf

# Many PDFs into a dedicated output folder
~/.local/docling-venv/bin/python ~/.claude/skills/pdf-to-md/scripts/convert.py a.pdf b.pdf -o ./md-out

# Whole directory of PDFs
~/.local/docling-venv/bin/python ~/.claude/skills/pdf-to-md/scripts/convert.py ./pdfs -o ./md-out

# Force OCR (e.g. the embedded font yields mojibake)
~/.local/docling-venv/bin/python ~/.claude/skills/pdf-to-md/scripts/convert.py scan.pdf --force-ocr

# Print Markdown to stdout instead of (or in addition to) writing a file
~/.local/docling-venv/bin/python ~/.claude/skills/pdf-to-md/scripts/convert.py report.pdf --stdout
```

## Behavior notes

- Output filename: `<pdf-stem>.md`, using the source filename with the extension swapped.
- The converter is cached within a single process, so converting many files in one
  invocation reloads models only once (much faster than one process per file).
- On failure of one file in a batch, the others still convert; the script exits non-zero.

## Environment

- **Venv:** `~/.local/docling-venv` (Python 3.11 via mise, `docling[rapidocr]`, ~2GB)
- **OCR engine:** RapidOCR (onnxruntime backend, PP-OCRv6 models)
- If the venv is ever missing or broken (e.g. after a wipe), recreate it:
  ```bash
  mise exec python@3.11 -- python -m venv ~/.local/docling-venv
  ~/.local/docling-venv/bin/pip install "docling[rapidocr]"
  ```
