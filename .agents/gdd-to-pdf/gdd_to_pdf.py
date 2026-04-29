#!/usr/bin/env python3
"""
gdd_to_pdf.py — Export docs/human-gdd.md to docs/human-gdd.pdf

Requires:
  pip install -r requirements.txt          (markdown, xhtml2pdf)
  npm install -g @mermaid-js/mermaid-cli   (mmdc, for diagram rendering)

Run from the project root:
  python workflow/scripts/gdd_to_pdf.py
"""

import base64
import io
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

INPUT_FILE = Path("docs/human-gdd.md")
OUTPUT_FILE = Path("docs/human-gdd.pdf")

CSS = """
body {
    font-family: Georgia, 'Times New Roman', serif;
    font-size: 13pt;
    line-height: 1.4;
    color: #222;
    max-width: 800px;
    margin: 0 auto;
    padding: 20px;
}
p { margin: 0 !important; padding: 0 !important; margin-bottom: 0.4em !important; }
h1 {
    font-size: 2em;
    border-bottom: 2px solid #333;
    padding-bottom: 0.3em;
    margin-top: 1em;
    margin-bottom: 0.4em;
}
h2 {
    font-size: 1.5em;
    border-bottom: 1px solid #ccc;
    padding-bottom: 0.2em;
    margin-top: 0.8em;
    margin-bottom: 0.3em;
}
h3 { font-size: 1.2em; margin-top: 0.6em; margin-bottom: 0.2em; }
h4 { font-size: 1em; margin-top: 0.4em; margin-bottom: 0.2em; }
code {
    font-family: 'Courier New', monospace;
    background: #f4f4f4;
    padding: 2px 4px;
    border-radius: 3px;
    font-size: 0.9em;
}
pre {
    background: #f4f4f4;
    border: 1px solid #ddd;
    padding: 12px;
    border-radius: 4px;
    overflow-x: auto;
    margin: 0.4em 0;
}
pre code { background: none; padding: 0; }
blockquote {
    border-left: 3px solid #aaa;
    margin: 0.3em 0;
    padding-left: 1em;
    color: #555;
}
img { max-width: 100%; height: auto; display: block; margin: 0.6em auto; }
table { border-collapse: collapse; width: 100%; margin: 0.5em 0; }
th, td { border: 1px solid #ccc; padding: 6px 10px; text-align: left; }
th { background: #f0f0f0; font-weight: bold; }
tr:nth-child(even) { background: #fafafa; }
ul, ol { padding-left: 1.5em; margin: 0.2em 0 !important; }
li { margin: 0 !important; padding: 0 !important; margin-bottom: 0.2em !important; }
li p { margin: 0 !important; padding: 0 !important; }
hr { border: none; border-top: 1px solid #ddd; margin: 1em 0; }
"""


# ---------------------------------------------------------------------------
# Dependency checks
# ---------------------------------------------------------------------------

def check_python_packages() -> None:
    missing = []
    try:
        import markdown  # noqa: F401
    except ImportError:
        missing.append("markdown")
    try:
        import xhtml2pdf  # noqa: F401
    except ImportError:
        missing.append("xhtml2pdf")
    if missing:
        print(f"ERROR: Missing Python packages: {', '.join(missing)}")
        print("       Install with: pip install -r requirements.txt")
        sys.exit(1)


def _mmdc_cmd() -> str | None:
    """Return the mmdc command name available on this platform, or None."""
    for name in ("mmdc", "mmdc.cmd"):
        if shutil.which(name):
            return name
    return None


def check_mmdc() -> None:
    if _mmdc_cmd() is None:
        print("ERROR: mermaid-cli (mmdc) not found on PATH.")
        print("       Install with: npm install -g @mermaid-js/mermaid-cli")
        sys.exit(1)


# ---------------------------------------------------------------------------
# Mermaid rendering
# ---------------------------------------------------------------------------

_MERMAID_PATTERN = re.compile(r"```mermaid\n(.*?)```", re.DOTALL)


def render_mermaid_blocks(md_text: str, tmp_dir: str) -> str:
    """
    Replace each ```mermaid ... ``` block with a rendered PNG image reference.
    Uses mmdc (mermaid-cli) for fully offline rendering.
    Falls back to a plain code block with a warning if rendering fails.
    """
    diagram_index = [0]

    def replace_block(match: re.Match) -> str:
        source = match.group(1)
        idx = diagram_index[0]
        diagram_index[0] += 1

        mmd_path = Path(tmp_dir) / f"diagram_{idx}.mmd"
        png_path = Path(tmp_dir) / f"diagram_{idx}.png"

        mmd_path.write_text(source, encoding="utf-8")

        result = subprocess.run(
            [_mmdc_cmd(), "-i", str(mmd_path), "-o", str(png_path),
             "-b", "white", "--width", "900"],
            capture_output=True,
            text=True,
            shell=(sys.platform == "win32"),
        )

        if result.returncode != 0 or not png_path.exists():
            print(f"  WARNING: Could not render diagram {idx}: {result.stderr.strip()}")
            return f"```\n{source}```"

        print(f"  Rendered diagram {idx} -> {png_path.name}")
        # Absolute path so xhtml2pdf resolves the file regardless of cwd
        return f"![diagram]({png_path.resolve().as_posix()})"

    return _MERMAID_PATTERN.sub(replace_block, md_text)


# ---------------------------------------------------------------------------
# HTML conversion
# ---------------------------------------------------------------------------

def _image_to_data_uri(path: Path) -> str | None:
    """Convert an image file to a base64 data URI (PNG).

    Handles .webp, .avif, .jpg, .png and any other format Pillow can read.
    Returns None if the file cannot be opened.
    """
    try:
        from PIL import Image
        with Image.open(path) as img:
            if img.mode not in ("RGB", "RGBA"):
                img = img.convert("RGB")
            buf = io.BytesIO()
            img.save(buf, format="PNG")
            b64 = base64.b64encode(buf.getvalue()).decode("ascii")
            return f"data:image/png;base64,{b64}"
    except Exception:
        return None


def build_html(md_text: str, base_dir: Path) -> str:
    """Convert markdown to a full HTML document with embedded CSS.

    All local image references are embedded as base64 data URIs so that
    xhtml2pdf can render them without file:// path issues.
    """
    import markdown as md_lib

    extensions = ["tables", "fenced_code", "toc", "nl2br", "extra"]
    body = md_lib.markdown(md_text, extensions=extensions)

    # Embed local images as base64 data URIs
    def embed_src(match: re.Match) -> str:
        src = match.group(1)
        if src.startswith(("http://", "https://", "data:")):
            return match.group(0)
        # Strip leading file:// if present
        if src.startswith("file:///"):
            abs_path = Path(src[8:])
        else:
            abs_path = (base_dir / src).resolve()
        if abs_path.exists():
            data_uri = _image_to_data_uri(abs_path)
            if data_uri:
                return f'src="{data_uri}"'
        return match.group(0)  # keep original if file not found / unreadable

    body = re.sub(r'src="([^"]+)"', embed_src, body)

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<style>
{CSS}
</style>
</head>
<body>
{body}
</body>
</html>"""


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> None:
    if not INPUT_FILE.exists():
        print(f"ERROR: {INPUT_FILE} not found.")
        print("       Complete gdd-1 through gdd-6 before exporting.")
        sys.exit(1)

    check_python_packages()
    check_mmdc()

    print(f"Reading {INPUT_FILE} ...")
    md_text = INPUT_FILE.read_text(encoding="utf-8")

    tmp_dir = tempfile.mkdtemp(prefix="gdd_pdf_")
    try:
        print("Rendering Mermaid diagrams ...")
        md_text = render_mermaid_blocks(md_text, tmp_dir)

        print("Converting to HTML ...")
        html = build_html(md_text, base_dir=INPUT_FILE.parent.resolve())

        print(f"Exporting PDF -> {OUTPUT_FILE} ...")
        from xhtml2pdf import pisa
        with open(str(OUTPUT_FILE), "wb") as pdf_file:
            result = pisa.CreatePDF(html, dest=pdf_file)
        if result.err:
            print(f"ERROR: PDF generation failed with {result.err} error(s).")
            sys.exit(1)

        print(f"\nDone: {OUTPUT_FILE.resolve()}")
    finally:
        shutil.rmtree(tmp_dir, ignore_errors=True)


if __name__ == "__main__":
    main()
