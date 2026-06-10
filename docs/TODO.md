# Website to-do / backlog

Living list of follow-ups for the marketing site. Keep it short; delete items when done.

## Open

- **Optional: Open Graph image dimensions.** For slightly faster/cleaner social previews,
  add `og:image:width` (1200), `og:image:height` (630), and `og:image:type` (`image/png`)
  meta tags alongside the existing `og:image` on each page. Not required — the PNG renders
  fine without them.
- **Content freshness — competitor facts.** The comparison page cites KLAS rankings, ownership,
  and licensing that change over time (e.g. KLAS is published yearly). Revisit annually and
  re-verify against the sources listed on `comparison.html`. Source of truth for our own
  built-vs-planned claims is the engine repo's `docs/` (notably `AI.md`, `PHI.md`).
- **Footer "spec" detail.** The footer badge row now reads as benefits (Open source / No
  lock-in / Self-hosted). If a quick spec (Python version, exact license) is wanted somewhere,
  the footer-bottom line already states the AGPL license.

## Home page — reframe technical content as customer benefits

Review pass (requested Jun 2026): the landing page leans too technical / internal in places.
Rework these around the **MEFOR benefits list** — free & open source, fast to deploy, fast
legacy migration, no vendor lock-in, reliable delivery — sourced from the engine's
`docs/marketing/COMPETITIVE-POSITIONING.md` "Available now" section and the comparison page's
"MessageFoundry advantage" points.

- **Remove the "At-least-once by construction" callout** (the amber callout in the model
  section) — too technical for the landing page.
- **Rework the "The model — Your configuration *is* the graph" section.** The
  graph / Connection / Router / Handler framing confuses a visitor ("what graph?"). Rebuild it
  around customer benefits instead of the architecture diagram — base it on the MEFOR benefits
  list rather than internal terminology.
- **Redo the "Why MessageFoundry" card bodies as benefits, not technical detail.** The titles
  were softened, but the bodies still read as engineering spec (SQLite-WAL inbox/outbox;
  python-hl7 / hl7apy *peek*; `PROCESSED` / `UNROUTED` / `FILTERED` / `ERROR` dispositions;
  PySide6 / parse-tree). State the customer benefit first; push the internals to the features
  page or drop them. (Applies to the "store is the queue", "tolerant-first parsing", "nothing
  is silently dropped", and "console & editor tooling" cards.)
- **Update the closing CTA band ("Code-first. Self-hosted. Open-source.").**
  (1) Make clear customers can **self-host on their own cloud**, not just on-prem.
  (2) Drop **"code-first"** as the lead — it's an internal idea, not a customer want. Stress
  **easy to configure with setup wizards, with full Python power when you need it.**

## New page — the product, shown by component (user-benefit view)

Create a page that introduces MessageFoundry's pieces from a **customer-benefit** angle — what
each does *for the user*, not how it's built. Cover the four components:

- **Monitoring console** — watch message flow live, search and inspect messages, and replay with
  a click; know your interfaces are healthy at a glance.
- **Configuration in VS Code** — a custom extension with **setup wizards** that write the config
  for you, plus full Python power when you need it; author, validate, and promote interfaces
  without leaving your editor.
- **A fast engine that runs as a service** — reliable and headless, runs as a background service
  where your data lives.
- **A complete testing harness** — prove interfaces work against synthetic data before go-live,
  both interactively and in CI.

Keep it benefit-first; the accurate technical specifics already live on the features page.

## Generated assets — how to regenerate

- **`assets/img/og.png`** is the social-share card, **rasterized from `assets/img/og.svg`**
  (browsers don't reliably render SVG Open Graph images, so the tags point at the PNG).
  It does **not** regenerate automatically — if you edit `og.svg`, re-export the PNG at
  1200×630 with headless Chrome/Edge:

  ```bash
  chrome --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
    --window-size=1200,630 \
    --screenshot="assets/img/og.png" "file:///ABSOLUTE/PATH/assets/img/og.svg"
  ```

  Keep `og.svg` and `og.png` copy in sync, and in sync with the live site's positioning.

- **Brand anvil glyph** lives in `assets/img/logo.svg`, `assets/img/favicon.svg`, and
  `assets/img/og.svg`. If the mark changes, update all three and re-export `og.png`.

## Recently done (Jun 2026)

- Added the AI-assistance / legacy-migration page (`ai.html`).
- Rebuilt the comparison page: 6-engine matrix + interactive competitor selector; corrected
  KLAS attribution (Corepoint #1; Rhapsody #2).
- Reframed home + features around benefits (free/open-source, fast deploy, legacy migration).
- Fixed the 404 page's missing mobile-nav toggle; removed unused `.kicker` CSS.
- Switched the OG image from SVG to a rasterized PNG and refreshed its copy.
