# PDF sources

Markdown sources for the branded documentation PDFs linked from the **Documents** section
of `/getting-started.html` and from `/architecture.html`. Each `<Name>.md` here renders to
`assets/docs/MessageFoundry-<Name>.pdf`.

These are **not served** — GitHub Pages (Jekyll, no `.nojekyll`) excludes `_`-prefixed
directories from the built site. They live in the repo so the PDFs stay reproducible and
editable.

## Regenerating a PDF

1. Render the markdown with **python-markdown** (extensions: `tables`, `fenced_code`,
   `sane_lists`, `toc`) wrapped in the shared branded print-CSS template — amber top rule,
   `Message`**`Foundry`** wordmark header, `v0.2rc1 · <month year>` meta, AGPL footer — into a
   temporary HTML file under `assets/docs/`.
2. Print that HTML to PDF with headless Chrome, then delete the temp HTML:

       chrome --headless=new --disable-gpu --no-pdf-header-footer \
         --user-data-dir="<throwaway dir>" \
         --print-to-pdf="<ABSOLUTE>/assets/docs/MessageFoundry-<Name>.pdf" \
         "file:///<ABSOLUTE>/assets/docs/_tmp.html"

   **Gotcha:** `--print-to-pdf` must be an **absolute** path — Chrome resolves a relative
   path against its own working dir and silently writes nothing (exit 0). Use an absolute
   path (or write to a temp file and move it in), and a throwaway `--user-data-dir` so an
   already-running Chrome doesn't swallow the headless call.

## Provenance

- **Engine-sourced** (`Mental-Model`, `User-Guide`, `Install-Guide`) — adapted from the
  engine repo's `docs/`: relative repo links rewritten to absolute
  `github.com/MEFORORG/MessageFoundry` URLs, version pins aligned to the `0.2.1` set, AD
  auth scoped to LDAP, and contributor-only framing (CLAUDE.md / ADR-internal notes) removed.
- The remaining docs were authored directly for the site.

All reflect the **v0.2rc1** target. Before treating version pins (`0.2.1`) or DICOM status as
final, resolve the open content flags (exact version string, DICOM shipped-vs-roadmap,
throughput numbers, HIPAA penalty year).
