#!/usr/bin/env python3
"""Render the MessageFoundry documentation markdown into branded PDFs.

    python render_pdf.py --all                 # every source, current PyPI version
    python render_pdf.py Install-Guide         # one doc
    python render_pdf.py --all --version 0.3.2 # pin the masthead explicitly
    python render_pdf.py --list                # show the source -> PDF mapping

Pipeline:  markdown -> _pdf-template.html -> headless Chrome --print-to-pdf.

Three things this script exists to get right, each of which has bitten before:

  1. **UTF-8, explicitly.** Python on Windows defaults to cp1252, which turns
     em-dashes into mojibake that ships into the PDF. Every read and write here
     names the encoding, and every render is verified for 0 occurrences of the
     tell-tale sequence before it is accepted.
  2. **Absolute --print-to-pdf path.** Chrome resolves a relative output path
     against its OWN working directory, silently writes nothing, and exits 0 --
     so the stale PDF survives and any content check passes falsely.
  3. **The masthead version must be current.** It defaults to whatever PyPI says
     right now rather than a constant that quietly rots.
"""
from __future__ import annotations

import argparse
import datetime as _dt
import io
import json
import os
import shutil
import subprocess
import sys
import tempfile
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))          # assets/docs/_md
ASSETS_DOCS = os.path.dirname(HERE)                        # assets/docs
ASSETS = os.path.dirname(ASSETS_DOCS)                      # assets
REPO = os.path.dirname(ASSETS)                             # repo root
TEMPLATE = os.path.join(HERE, "_pdf-template.html")

MOJIBAKE = "\u00e2\u20ac"          # 'â€' — what a cp1252-decoded em-dash looks like
PYPI_JSON = "https://pypi.org/pypi/messagefoundry/json"

# Sources that don't live in assets/docs/_md/, with their published destination.
EXTRA_SOURCES = {
    "Secure-Development-Standards": (
        os.path.join(REPO, "docs", "secure-development-standards.md"),
        os.path.join(ASSETS, "MessageFoundry-Secure-Development-Standards.pdf"),
    ),
}

CHROME_CANDIDATES = [
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    "/usr/bin/google-chrome",
    "/usr/bin/chromium",
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
]


def find_chrome() -> str:
    for p in CHROME_CANDIDATES:
        if os.path.exists(p):
            return p
    for name in ("chrome", "google-chrome", "chromium", "msedge"):
        found = shutil.which(name)
        if found:
            return found
    sys.exit("No Chrome/Edge binary found — install one or edit CHROME_CANDIDATES.")


def current_version() -> str:
    try:
        with urllib.request.urlopen(PYPI_JSON, timeout=20) as r:
            return json.load(r)["info"]["version"]
    except Exception as exc:                                    # noqa: BLE001
        sys.exit(
            "Could not read the current version from PyPI (%s: %s).\n"
            "Pass it explicitly, e.g. --version 0.3.2 — but check PyPI first; "
            "the masthead must not carry a stale version." % (type(exc).__name__, exc)
        )


def sources() -> dict[str, tuple[str, str]]:
    """name -> (markdown path, pdf path)"""
    out = {}
    for fn in sorted(os.listdir(HERE)):
        if not fn.endswith(".md") or fn == "README.md":
            continue
        name = fn[:-3]
        out[name] = (
            os.path.join(HERE, fn),
            os.path.join(ASSETS_DOCS, "MessageFoundry-%s.pdf" % name),
        )
    out.update(EXTRA_SOURCES)
    return out


_DELIM_ROW = __import__("re").compile(r"^\s*\|[\s:\-|]+\|\s*$")


def normalize_markdown(md_text: str) -> str:
    """Insert the blank line python-markdown needs before a table.

    GitHub's renderer is lenient: a table that starts on the line straight after a
    paragraph still becomes a table. python-markdown's `tables` extension is not --
    it absorbs the header into the preceding paragraph and the whole table degrades
    into prose full of literal `|` characters. Configuration.md has nine of these.

    Rather than churn the sources (they are correct for GitHub), normalize here.
    """
    lines = md_text.split("\n")
    out: list[str] = []
    for i, line in enumerate(lines):
        is_header = (
            line.lstrip().startswith("|")
            and i + 1 < len(lines)
            and _DELIM_ROW.match(lines[i + 1])
        )
        if is_header and out and out[-1].strip() and not out[-1].lstrip().startswith("|"):
            out.append("")
        out.append(line)
    return "\n".join(out)


def split_title(md_text: str) -> tuple[str, str]:
    """Lift the leading '# Title' into the masthead so it isn't printed twice."""
    lines = md_text.split("\n")
    for i, line in enumerate(lines):
        if line.startswith("# "):
            return line[2:].strip(), "\n".join(lines[:i] + lines[i + 1:])
        if line.strip():
            break                                   # content before any H1 — leave as-is
    return "Documentation", md_text


def render_html(md_path: str, version: str, date: str) -> tuple[str, str]:
    import markdown

    raw = normalize_markdown(io.open(md_path, encoding="utf-8").read())
    title, body_md = split_title(raw)
    body_html = markdown.markdown(
        body_md,
        extensions=["tables", "fenced_code", "sane_lists", "toc"],
        output_format="html5",
    )
    tpl = io.open(TEMPLATE, encoding="utf-8").read()
    html = (
        tpl.replace("{{TITLE}}", title)
           .replace("{{VERSION}}", "v" + version.lstrip("v"))
           .replace("{{DATE}}", date)
           .replace("{{YEAR}}", date.split()[-1])
           .replace("{{CONTENT}}", body_html)
    )
    return title, html


def to_pdf(chrome: str, html: str, pdf_path: str) -> None:
    pdf_path = os.path.abspath(pdf_path)                        # gotcha #2
    os.makedirs(os.path.dirname(pdf_path), exist_ok=True)
    tmp_html = os.path.join(ASSETS_DOCS, "_render_tmp.html")
    io.open(tmp_html, "w", encoding="utf-8", newline="\n").write(html)
    profile = tempfile.mkdtemp(prefix="mf-render-")
    try:
        res = subprocess.run(
            [chrome, "--headless=new", "--disable-gpu", "--no-pdf-header-footer",
             "--user-data-dir=" + profile,
             "--print-to-pdf=" + pdf_path,
             "file:///" + tmp_html.replace("\\", "/")],
            capture_output=True, text=True, timeout=180,
        )
        if not os.path.exists(pdf_path):
            sys.exit("Chrome wrote no PDF for %s\n%s" % (pdf_path, res.stderr[-800:]))
    finally:
        if os.path.exists(tmp_html):
            os.remove(tmp_html)
        shutil.rmtree(profile, ignore_errors=True)


def verify(pdf_path: str, version: str) -> tuple[int, bool, bool]:
    from pypdf import PdfReader

    reader = PdfReader(pdf_path)
    text = "\n".join((p.extract_text() or "") for p in reader.pages)
    return len(reader.pages), MOJIBAKE not in text, ("v" + version.lstrip("v")) in text


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("names", nargs="*", help="doc names, e.g. Install-Guide")
    ap.add_argument("--all", action="store_true", help="render every source")
    ap.add_argument("--list", action="store_true", help="show the source -> PDF mapping")
    ap.add_argument("--version", help="masthead version (default: current PyPI release)")
    ap.add_argument("--date", help='masthead date (default: "Month YYYY" today)')
    ap.add_argument("--out-dir", help="write PDFs here instead of over the published ones "
                                      "(use this to preview before replacing a live set)")
    args = ap.parse_args()

    sys.stdout.reconfigure(encoding="utf-8")
    src = sources()

    if args.list:
        for name, (md, pdf) in src.items():
            print("%-34s %s" % (name, os.path.relpath(pdf, REPO)))
        return 0

    targets = list(src) if args.all else args.names
    if not targets:
        ap.error("name a doc, or pass --all (or --list to see them)")
    unknown = [t for t in targets if t not in src]
    if unknown:
        sys.exit("Unknown doc(s): %s\nTry --list." % ", ".join(unknown))

    version = args.version or current_version()
    date = args.date or _dt.date.today().strftime("%B %Y")
    chrome = find_chrome()
    print("version %s   date %s   renderer %s\n" % (version, date, os.path.basename(chrome)))

    failures = 0
    for name in targets:
        md_path, pdf_path = src[name]
        if args.out_dir:
            pdf_path = os.path.join(args.out_dir, os.path.basename(pdf_path))
        title, html = render_html(md_path, version, date)
        to_pdf(chrome, html, pdf_path)
        pages, clean, stamped = verify(pdf_path, version)
        ok = clean and stamped
        failures += 0 if ok else 1
        print("%-34s %3d pp  %-9s %s%s" % (
            name, pages, "%.0f KB" % (os.path.getsize(pdf_path) / 1024),
            "OK " if ok else "FAIL",
            "" if ok else ("  [%s%s]" % ("mojibake " if not clean else "",
                                         "version-not-found" if not stamped else "")),
        ))
    print("\n%d rendered, %d failed" % (len(targets), failures))
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
