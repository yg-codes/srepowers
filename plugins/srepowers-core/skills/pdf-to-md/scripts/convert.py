#!/usr/bin/env python3
"""Convert PDF(s) to Markdown using the local docling + RapidOCR venv.

Run with the venv's own interpreter (the skill invokes this as
~/.local/docling-venv/bin/python convert.py ...), so it always uses the
pinned docling stack regardless of the caller's working directory or PATH.

OCR policy: docling runs OCR only when a page has no extractable text layer.
For a digital-native PDF this means fast, perfect native-text extraction; for
a scanned/image-only PDF it transparently OCRs via RapidOCR. Pass --force-ocr
to OCR every page even when a text layer exists (e.g. text is garbage glyphs).
"""
import argparse
import sys
from pathlib import Path

from docling.datamodel.base_models import InputFormat
from docling.datamodel.pipeline_options import PdfPipelineOptions, RapidOcrOptions
from docling.document_converter import DocumentConverter, PdfFormatOption

# Cached so multi-file runs don't reload models per file.
_CONVERTER_CACHE = {}


def get_converter(do_ocr: bool, force_ocr: bool):
    key = (do_ocr, force_ocr)
    if key not in _CONVERTER_CACHE:
        pipe = PdfPipelineOptions()
        pipe.do_ocr = do_ocr
        if do_ocr and force_ocr:
            pipe.ocr_options = RapidOcrOptions(force_full_page_ocr=True)
        _CONVERTER_CACHE[key] = DocumentConverter(
            format_options={InputFormat.PDF: PdfFormatOption(pipeline_options=pipe)}
        )
    return _CONVERTER_CACHE[key]


def convert_one(src: Path, converter, out_dir: Path | None, print_stdout: bool) -> bool:
    """Convert a single PDF. Returns True on success."""
    try:
        result = converter.convert(str(src))
        md = result.document.export_to_markdown()
    except Exception as e:
        print(f"[FAIL] {src}: {type(e).__name__}: {e}", file=sys.stderr)
        return False

    if out_dir:
        out_dir.mkdir(parents=True, exist_ok=True)
        dest = out_dir / f"{src.stem}.md"
        dest.write_text(md, encoding="utf-8")
        print(f"[OK] {src.name} -> {dest}")
    if print_stdout or not out_dir:
        if out_dir:
            print(f"\n--- {src.name} ---")
        print(md)
    return True


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("source", nargs="+", help="PDF file(s) and/or directory(ies) to convert")
    ap.add_argument("-o", "--out", help="Output directory (default: next to each source file)")
    ap.add_argument("--no-ocr", action="store_true", help="Never OCR (native text layer only; fails on image-only PDFs)")
    ap.add_argument("--force-ocr", action="store_true", help="OCR every page even if a text layer exists")
    ap.add_argument("--stdout", action="store_true", help="Also print Markdown to stdout")
    args = ap.parse_args()

    # Expand any directories into their .pdf files.
    pdfs: list[Path] = []
    for s in args.source:
        p = Path(s)
        if p.is_dir():
            pdfs.extend(sorted(p.glob("*.pdf")))
        elif p.is_file():
            pdfs.append(p)
        else:
            print(f"[skip] not found: {s}", file=sys.stderr)
    if not pdfs:
        sys.exit("error: no PDF files found in the given source(s)")

    out_dir = Path(args.out) if args.out else None
    converter = get_converter(do_ocr=not args.no_ocr, force_ocr=args.force_ocr)

    ok = 0
    for pdf in pdfs:
        target_dir = out_dir if out_dir else pdf.parent
        if convert_one(pdf, converter, target_dir, args.stdout):
            ok += 1
    print(f"\nDone: {ok}/{len(pdfs)} converted.", file=sys.stderr)
    sys.exit(0 if ok == len(pdfs) else 1)


if __name__ == "__main__":
    main()
