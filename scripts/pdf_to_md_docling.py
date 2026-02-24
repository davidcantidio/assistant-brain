#!/usr/bin/env python3
"""Deterministic PDF -> Markdown converter using Docling."""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path


EXIT_OK = 0
EXIT_INPUT_MISSING = 2
EXIT_DOCLING_ERROR = 3
EXIT_EMPTY_MARKDOWN = 4


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Convert a PDF file to Markdown using Docling."
    )
    parser.add_argument(
        "--input",
        required=True,
        help="Input PDF path.",
    )
    parser.add_argument(
        "--output",
        required=False,
        help="Output Markdown path. Default: same input name with .md extension.",
    )
    return parser.parse_args(argv)


def resolve_output_path(input_path: Path, output_arg: str | None) -> Path:
    if output_arg:
        return Path(output_arg)
    return input_path.with_suffix(".md")


def normalize_markdown(content: str) -> str:
    # Normalize line endings and remove trailing spaces to reduce diff noise.
    normalized = content.replace("\r\n", "\n").replace("\r", "\n")
    lines = [line.rstrip() for line in normalized.split("\n")]
    normalized = "\n".join(lines).rstrip("\n")
    if normalized:
        normalized += "\n"
    return normalized


def convert_pdf_to_markdown(input_path: Path) -> str:
    try:
        from docling.datamodel.base_models import InputFormat
        from docling.datamodel.pipeline_options import PdfPipelineOptions
        from docling.document_converter import DocumentConverter, PdfFormatOption
    except Exception as exc:  # pragma: no cover - import error path
        raise RuntimeError(f"Docling import failed: {exc}") from exc

    try:
        timeout_seconds = int(os.environ.get("DOCLING_DOCUMENT_TIMEOUT", "120"))
        pdf_options = PdfPipelineOptions()
        pdf_options.do_ocr = False
        pdf_options.do_table_structure = False
        pdf_options.document_timeout = timeout_seconds

        converter = DocumentConverter(
            format_options={
                InputFormat.PDF: PdfFormatOption(pipeline_options=pdf_options),
            }
        )
        result = converter.convert(str(input_path))
        return result.document.export_to_markdown()
    except Exception as exc:
        raise RuntimeError(f"Docling conversion failed: {exc}") from exc


def write_output(output_path: Path, content: str) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", encoding="utf-8", newline="\n") as handle:
        handle.write(content)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    input_path = Path(args.input)

    if not input_path.exists() or not input_path.is_file():
        print(
            f"ERROR[{EXIT_INPUT_MISSING}]: input file not found: {input_path}",
            file=sys.stderr,
        )
        return EXIT_INPUT_MISSING

    output_path = resolve_output_path(input_path, args.output)

    try:
        raw_markdown = convert_pdf_to_markdown(input_path)
    except Exception as exc:
        print(f"ERROR[{EXIT_DOCLING_ERROR}]: {exc}", file=sys.stderr)
        return EXIT_DOCLING_ERROR

    # Controlled path to validate empty-output handling in tests.
    if os.environ.get("DOCLING_TEST_EMPTY_OUTPUT") == "1":
        raw_markdown = ""

    normalized_markdown = normalize_markdown(raw_markdown or "")
    if not normalized_markdown.strip():
        print(
            f"ERROR[{EXIT_EMPTY_MARKDOWN}]: generated markdown is empty for input: {input_path}",
            file=sys.stderr,
        )
        return EXIT_EMPTY_MARKDOWN

    try:
        write_output(output_path, normalized_markdown)
    except Exception as exc:
        print(f"ERROR[{EXIT_DOCLING_ERROR}]: failed to write output: {exc}", file=sys.stderr)
        return EXIT_DOCLING_ERROR

    print(str(output_path))
    return EXIT_OK


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
