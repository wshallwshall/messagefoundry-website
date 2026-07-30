# PDF sources

Markdown sources for the branded documentation PDFs linked from the **Documents** section
of `/getting-started.html` and from `/architecture.html`. Each `<Name>.md` here renders to
`assets/docs/MessageFoundry-<Name>.pdf`.

These are **not served** — GitHub Pages (Jekyll, no `.nojekyll`) excludes `_`-prefixed
directories from the built site. They live in the repo so the PDFs stay reproducible and
editable.

## Regenerating a PDF

Two files own this: **`_pdf-template.html`** (the branded print template) and
**`render_pdf.py`** (the renderer). Both live here, beside the sources they render.

**This is the canonical renderer for every PDF in the set** — all 19 are generated from it.
Don't render these by another route: a second toolchain drifts in styling, and the whole
reason the template now lives in the repo is that it previously existed only as a
description, leaving the PDFs unreproducible and stale behind their sources.

```bash
pip install markdown pypdf                     # one-time; needs Chrome or Edge too

python render_pdf.py --list                    # source -> PDF mapping (19 docs)
python render_pdf.py Install-Guide             # one doc
python render_pdf.py --all                     # the whole set
python render_pdf.py --all --out-dir ../../../_preview   # preview without replacing live PDFs
```

The masthead version defaults to **whatever PyPI reports right now**, so it cannot quietly
rot; pass `--version` only to pin it deliberately. Every render is verified before it is
accepted — the text must extract, carry the version stamp, and contain zero mojibake.

### Editing the template

`_pdf-template.html` holds the placeholders `{{TITLE}}`, `{{VERSION}}`, `{{DATE}}`,
`{{YEAR}}` and `{{CONTENT}}`. Its colour tokens mirror `:root` in the site's
`assets/css/styles.css` — reuse them rather than introducing new values. Brand rules it
encodes, which should survive any edit:

- The **amber "Foundry" wordmark accent is masthead-only**. Never accent the brand name in
  body copy.
- The **trademark mark belongs to the logo lockup only**.
- **MEFOR-ORG** is the legal entity in the colophon; **MessageFoundry** is the product.
- The masthead and colophon are a page-1 title block and an end-of-document block — neither
  is a running header/footer.

### Three things that have bitten before

1. **`--print-to-pdf` must be an absolute path.** Chrome resolves a relative path against
   its *own* working directory, silently writes nothing, and exits 0 — so the stale PDF
   survives and a content check passes falsely. The script always absolutises it, and uses a
   throwaway `--user-data-dir` so an already-running Chrome can't swallow the headless call.
2. **Decode as UTF-8 explicitly.** Python on Windows defaults to cp1252, which turns
   em-dashes into mojibake that ships into the PDF. The script names the encoding on every
   read and write, then greps the rendered text to prove it.
3. **python-markdown needs a blank line before a table.** GitHub renders a table that starts
   immediately after a paragraph; python-markdown absorbs it into that paragraph and the
   table degrades into prose full of literal `|`. `Configuration.md` has nine of these, so
   the script normalises the markdown before conversion rather than churning the sources.

## Provenance

- **Engine-sourced** (`Mental-Model`, `User-Guide`, `Install-Guide`) — adapted from the
  engine repo's `docs/`: relative repo links rewritten to absolute
  `github.com/MEFORORG/MessageFoundry` URLs, version pins aligned to the current `0.3.2` release, AD
  auth scoped to LDAP, and contributor-only framing (CLAUDE.md / ADR-internal notes) removed.
- The remaining docs were authored directly for the site.

Version pins track the current PyPI release (`0.3.2`) — check
[PyPI](https://pypi.org/project/messagefoundry/) before treating any pin as final, and
resolve the open content flags (DICOM shipped-vs-roadmap, throughput numbers, HIPAA
penalty year).
