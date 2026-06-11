# Website to-do / backlog

Living list of follow-ups for the marketing site. Keep it short; delete items when done.

## Open

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

## Reference docs

- **`docs/COMPETITIVE-POSITIONING.md`** — the canonical positioning doc the comparison page is built
  from (sourced KLAS / ownership / licensing facts, built-vs-planned split). Keep `comparison.html`
  aligned with it; it mirrors the engine repo's `docs/marketing/COMPETITIVE-POSITIONING.md`.

## Security review — PDF follow-up

`security.html` is live, with the "full review" links pointing at the engine repo's `docs/security/`
folder for now. Follow-up: produce a formatted, downloadable **PDF** from the engine's
`CISO-REVIEW.md` and swap those links to it. Also decide whether to promote the page from the footer
into the top nav (kept footer-only to avoid a 7th crowded nav item).

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
- Shipped the **Overview** page (`overview.html`) — the four-component product tour — wired into the
  nav, footer, and sitemap on every page, with the copy fixes (wizard claim, at-least-once,
  environment wording) applied. Raised the mobile-nav breakpoint to 980px so a 6th nav item doesn't
  crowd the header.
- Shipped the **Security & PHI** page (`security.html`) — built-and-enforced controls (auth, RBAC,
  revocable sessions, hash-chained audit, at-rest encryption, nothing-dropped), an honest Phase-1
  posture + roadmap (no-TLS-yet; MFA / retention / redaction / de-id planned), and a transparency /
  "read the review" section. Aligned to the engine's **CISO review**, not the simplified marketing
  positioning. Wired into the footer + sitemap + a home contextual link (footer-only, not top nav).
- Aligned the AD/Kerberos auth wording for accuracy (LDAPS; Kerberos experimental).
- Added a one-line CI/CD benefit to the home ("Ships through your own CI/CD") and overview
  ("Pipeline-ready") pages, and Open Graph image dimension/type meta tags (1200×630, PNG) to every
  page.
