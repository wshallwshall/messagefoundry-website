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

## Open question — delivery semantics (product decision, not copy)

Owner wants the copy to say interfaces deliver **once, in order**. The engine's *documented* guarantee
is **at-least-once** — an outbound whose ACK is lost is retried, so a receiver may see a duplicate and
receivers must be idempotent (`docs/CONNECTIONS.md`), and there is **no documented in-order guarantee**.
The site copy was therefore reworded to lead with **reliable, nothing-lost** delivery rather than
claiming exactly-once / in-order. **Decision needed:** keep the reliable / no-loss framing (current),
or treat exactly-once + ordering as an engine capability to build and document first, then update copy.

## CI/CD — optional remainder

The comparison matrix CI/CD row and a features CI/CD section are live. Optional follow-up: a one-line
CI/CD benefit on the **home** and **product** pages.

## Reference docs

- **`docs/COMPETITIVE-POSITIONING.md`** — the canonical positioning doc the comparison page is built
  from (sourced KLAS / ownership / licensing facts, built-vs-planned split). Keep `comparison.html`
  aligned with it; it mirrors the engine repo's `docs/marketing/COMPETITIVE-POSITIONING.md`.

## New page — the product, shown by component (user-benefit view)

Create a page that introduces MessageFoundry's pieces from a **customer-benefit** angle — what
each does *for the user*, not how it's built. Cover the four components:

- **Monitoring console** — watch message flow live, search and inspect messages, and replay with
  a click; know your interfaces are healthy at a glance.
- **Configuration in VS Code** — a custom extension with **setup wizards** that generate the wiring
  for you, plus full Python power when you need it; author, validate, and promote interfaces
  without leaving your editor.
- **A fast engine that runs as a service** — reliable and headless, runs as a background service
  where your data lives.
- **A complete testing harness** — prove interfaces work against synthetic data before go-live,
  both interactively and in CI.

Keep it benefit-first; the accurate technical specifics already live on the features page.
**Status:** built as `product.html` (uncommitted/un-wired) — awaiting a nav-label decision
(Product / Overview / Tour / footer-only) before wiring it into nav, footer, and sitemap.

## New page — security & PHI review (summary + PDF)

Add a security review page positioned as a **trust** page: a concise summary of why
MessageFoundry is a strong, secure choice for **PHI**, with a link to a **full PDF** (still to
be developed).

- **Page = summary.** Lead with the security/PHI story at a benefit level: encryption at rest
  (AES-256-GCM), authentication (local / Active Directory / Kerberos), deny-by-default RBAC with
  per-channel scoping, a tamper-evident hash-chained audit log, a localhost-bound API by default,
  PHI-safe (code-only) AI assistance, and nothing-silently-dropped delivery. Note the
  open-source / source-available transparency angle too.
- **PDF = details.** Link to a downloadable full security review PDF (to come). The PDF is to be
  produced from the engine's **CISO / security markdown doc** (engine repo `docs/security/`).
  The page can ship first with a placeholder link until the PDF exists.
- Wire the new page into the header nav, footer, and sitemap when built. Keep every claim aligned
  with the engine's actual `docs/SECURITY.md` / `docs/PHI.md` (built vs planned).

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
- Retargeted the home hero at interface managers escaping costly legacy engines; fixed the
  mobile headline wrap.
- Reframed the home page around customer benefits: dropped the at-least-once callout and the
  architecture/"graph" section (replaced with a "Why switch" cost-and-migration section),
  rewrote the "Why MessageFoundry" card bodies, and updated the closing CTA.
- Copy pass: reworded "at-least-once" → reliable / nothing-lost (see Open question), softened the
  "wizards write the Python" claim, fixed the orphaned heading wrap (`text-wrap: balance`), tightened
  the "A balanced read" callout, reworded the "Why switch" h2 (prices + lock-in), and changed
  "self-host on your own cloud" → "in your own environment".
- Removed the "code-first" framing site-wide (footers, features h1/leads/meta, comparison
  intro/matrix/wedges, index meta/OG/Twitter, about status) — reframed around "analysts and
  developers alike".
- Added modern CI/CD to the positioning **and** the site (comparison matrix row + a features CI/CD
  section).
